#include "mex.h"
#include <iostream>
#include <stdio.h>
#include "class_handle.hpp"
//#include "MxArray_.hpp"
//#include "mexopencv.hpp"
//#include "opencvmex.hpp"
#include <opencv2/world.hpp>
#include <opencv2/opencv.hpp>

#include <thread>
#include <mutex>
#include <chrono>
#include <deque>
#include<algorithm>

using namespace std;
using namespace cv;

// utility struct that will come handy later
struct getMeanValReturnStr
{
    double* Data;
    double* Time;
};

// C++ class interfacing with matlab to implement a sensible video reader
class SimpleVideoReader
{
public:
    // props
    list<string> videoPaths;
    VideoCapture cap;
    int bufferSize = 600;       // Usually 10 seconds
    double speed = 1;
    mutable std::mutex mtx;
    deque<Mat> buffer;
    deque<double> bufferMs;
    int seekNFramesLoad = 10;

    int direction = 1;          // 1 forward, -1 backwards

    Mat thumb;
    //vector<float> ROI(4, -1);
    Rect ROI;

    int nFrames;
    struct meta {
        double frameRate;
        int nFrames;
        int width;
        int height;
        chrono::microseconds frameInterval;
    };
    list<meta> Meta;
    vector<chrono::milliseconds> videoDurations;                    // array of durations to be searched during seek. It should be intrinsecally ordered by construction
    vector<chrono::milliseconds>::iterator lastDuration;
                                                                    /*
    list<double> frameRate;
    list<int> nFrames;
    list<int> width;
    list<int> height;
    list<chrono::microseconds> frameInterval;*/

    list<meta>::iterator MetaIndex;
    list<string>::iterator PathsIndex;


    int frameIndex = -1, bufferIndex = -1, diskIndex = -1;
    atomic<bool> videoEnabled = false;
    atomic<bool> bufferEnabled = false;

    atomic<bool> videoRunning = false;
    atomic<bool> bufferRunning = false;
    





    // public methods
    SimpleVideoReader() {
        //mexPrintf("Calling default constructor\n");
    }

    SimpleVideoReader(const mxArray* videoPath_) {
        // constructor, check for file existance and opens it using openCV
        if (!mxIsCell(videoPath_)) {
            mexErrMsgTxt("Argument should be a cell array of video paths."); /*This function will return control to MATLAB*/
        }

        if (!mexIsLocked()) { // This is the first call to the function
         /* lock thread so that no-one accidentally clears function */
            mexLock();
        }


        //mexPrintf("Calling constructor\n");

        mwSize total_num_of_cells;
        /*Extract the cotents of MATLAB cell into the C array*/
        total_num_of_cells = mxGetNumberOfElements(videoPath_);
        string thisPath;
        videoDurations.push_back(chrono::milliseconds(0));
        nFrames = 0;
        for (auto i = 0; i < total_num_of_cells; i++) {
            thisPath = mxArrayToString(mxGetCell(videoPath_, i));
            cap.open(thisPath, CAP_FFMPEG);
            videoPaths.push_back(thisPath);
            // if not success, exit program
            if (cap.isOpened() == false) {
                mexUnlock();
                mexErrMsgTxt("Cannot open the video file\n");
                return;
            }


           int width = (int)cap.get(CAP_PROP_FRAME_WIDTH);
           int height = (int)cap.get(CAP_PROP_FRAME_HEIGHT);
           int  nFrames_ = (int)cap.get(CAP_PROP_FRAME_COUNT);
           double frameRate = (double)cap.get(CAP_PROP_FPS);
            // Get the properties of the video
            //width.push_back( (int)cap.get(CAP_PROP_FRAME_WIDTH));
            //height.push_back((int)cap.get(CAP_PROP_FRAME_HEIGHT));
            // set initial ROI to full image
            ROI.x = 0;  ROI.y = 0;
            ROI.width = width; ROI.height = height;

            nFrames += nFrames_;
            //frameRate.push_back( (double)cap.get(CAP_PROP_FPS));
            //nFrames.push_back( (int)cap.get(CAP_PROP_FRAME_COUNT));
            chrono::microseconds s((int) floor(1000000 / frameRate));
            chrono::milliseconds d((int)floor( 1000 * (nFrames_) / frameRate + videoDurations.back().count()));

            meta thisMeta;
            thisMeta.width = width;
            thisMeta.height = height;
            thisMeta.nFrames = nFrames_;
            thisMeta.frameRate = frameRate;
            thisMeta.frameInterval = s ;

            videoDurations.push_back(d);

            Meta.push_back(thisMeta);
            cap.release();
        }
        lastDuration = videoDurations.begin();
        MetaIndex = Meta.begin();
        PathsIndex = videoPaths.begin();
        cap.open(*PathsIndex, CAP_FFMPEG);

        cap >> thumb;
    }

    ~SimpleVideoReader() {
        videoEnabled = false;
        bufferEnabled = false;
        while (bufferRunning && videoRunning)
            this_thread::sleep_for(chrono::milliseconds(1));
        if (mexIsLocked()) { // This is the first call to the function
        /* lock thread so that no-one accidentally clears function */
            mexUnlock();
        }

       // mexPrintf("Calling destructor\n");
         }

    void startBuffer() {
        //mexPrintf("fBuffer started\n");
        //VideoCapture cap(videoPath);
        int sleepingTime = 10;
        bufferEnabled = true; bufferRunning = true;

        //cap.set(CAP_PROP_POS_FRAMES, frameIndex);
        while(bufferEnabled){
            int thisSize   = buffer.size() - bufferSize / 2;
            int targetSize = bufferSize ;
            // if the buffer is almost empty
            if ( thisSize <= targetSize ) {
                // reload some frames
                while ((buffer.size() <= bufferSize) && bufferEnabled){
                   
                    // read next frame and get info
                    Mat frame_;

                    bool success = cap.read(frame_);
                    double ms = cap.get(CAP_PROP_POS_MSEC) + lastDuration->count();
                    double fr = cap.get(CAP_PROP_POS_FRAMES);
                    diskIndex = fr;

                    // check if we have reached the end of file
                    if(diskIndex >= MetaIndex->nFrames){
                        // if this is the last file we exit
                        if (MetaIndex == Meta.end()) {
                            bufferEnabled = false;
                            return;
                        }
                        // else we get the next file
                        MetaIndex++;
                        PathsIndex++;
                        lastDuration++;
                        diskIndex = 0;
                        cap.release();
                        cap.open(*PathsIndex,CAP_FFMPEG);
                        
                    }
                    // lock the mutex and push frame to the buffer
                    mtx.lock();
                    buffer.push_back(frame_);
                    bufferMs.push_back(ms);
                    mtx.unlock();
                }
            }
            else {
                // otherwise just wait
                this_thread::sleep_for(chrono::milliseconds(1));
            }
        }

        //mexPrintf("fBuffer Stopped\n");
        bufferRunning = false;
    }

    void play() {
        //mexPrintf("Calling play\n");
        //VideoCapture cap(videoPath);
        videoRunning = true;
        videoEnabled = true;
        dispFrames();
        videoRunning = false;

        }

    double getTime() {
        return bufferMs.at(bufferIndex);
    }

void frameF(){
    direction = 1;
    videoEnabled = false;
    while (videoRunning)
        this_thread::sleep_for(chrono::milliseconds(1));
    dispFrames();
       
}

void frameB(){
    direction = -1;
    videoEnabled = false;
    while (videoRunning)
        this_thread::sleep_for(chrono::milliseconds(1));
    dispFrames();
}

void dispFrames(){         
    auto fInterval = chrono::duration_cast<chrono::microseconds>(MetaIndex->frameInterval);
    auto start = chrono::system_clock::now();

    if (videoEnabled && bufferIndex > bufferSize / 2 - 1) {
        buffer.erase(buffer.begin(), buffer.begin() + bufferIndex - bufferSize / 2 + 1);
        bufferIndex = bufferSize / 2 - 1;
       while (buffer.size() < (bufferSize / 2 + 2))
           this_thread::sleep_for(std::chrono::milliseconds(50));
    }

    do {      
        mtx.lock();

        if (videoEnabled && buffer.size() < (bufferSize/2+2)) {
            mtx.unlock();
            break;
        }
        Mat frame_ = buffer.at(bufferIndex + direction);
        double ms = bufferMs.at(bufferIndex + direction);
        bufferIndex += direction;

        if (bufferIndex == bufferSize / 2 && videoEnabled) {
            bufferIndex -= 1; //max(0, min(bufferIndex, bufferSize / 2 - 1));
            buffer.pop_front();
            bufferMs.pop_front();
        }
        else
            bufferIndex = max(0, min(bufferIndex, (int)buffer.size()-2));

        mtx.unlock();
        if (frame_.size().width >= ROI.width && frame_.size().height >= ROI.height) {
            thumb = frame_;
            string str = to_string(ms);
            putText(frame_, str.substr(0, str.find(".")), Point(ROI.x +5,ROI.y + ROI.height - 5), FONT_HERSHEY_SIMPLEX, 2, Scalar(255, 255, 255), 2, LINE_8, false);
            this_thread::sleep_until(start + fInterval/speed);
            imshow("Video", frame_(ROI));
            start = chrono::system_clock::now();
            if (waitKey(1) == 27)
                break;
        }

    } while (videoEnabled);

    };

 void pause() {
        videoEnabled = false;
    }
    
 void stopBuffer() {
        bufferEnabled = false;
    }

 void showThumb() {
        namedWindow("Video", WINDOW_NORMAL | WINDOW_KEEPRATIO);// Create a window for display.
        imshow("Video", thumb);                   // Show our image inside it.


    }

 void seek(double msTime) {
     videoEnabled = false;
     bufferEnabled = false;
     while(bufferRunning || videoRunning)
        this_thread::sleep_for(chrono::milliseconds(1));
     
     // erase the buffer
     mtx.lock();
        buffer.erase(buffer.begin(), buffer.end());
        bufferMs.erase(bufferMs.begin(), bufferMs.end());
     mtx.unlock();
     msTime = msTime - chrono::duration_cast<chrono::milliseconds>(MetaIndex->frameInterval).count() * seekNFramesLoad;
     bufferIndex = seekNFramesLoad - 1;
     //frameIndex = (int)floor(chrono::duration<double,milli>(msTime) / frameInterval) - 1;

     // find the videofile index based on the msTime
     lastDuration = lower_bound(videoDurations.begin(), videoDurations.end(), chrono::milliseconds( (int)floor(msTime)) ) - 1;
     int64_t n = distance(videoDurations.begin(), lastDuration) - distance(videoPaths.begin(), PathsIndex);
     advance(PathsIndex, n);
     //advance(MetaIndex, n);
     
     // open the correct videofile
     mtx.lock();
        cap.release();
        cap.open(*PathsIndex, CAP_FFMPEG);
        cap.set(CAP_PROP_POS_MSEC, msTime - lastDuration->count());
     mtx.unlock();
 }

 void drawROI() {
     // if window is closed, open it
     if (getWindowProperty("Video", WND_PROP_AUTOSIZE) == -1)
         showThumb();

     ROI = selectROI("Video", thumb, true, false);
 }

 getMeanValReturnStr getMeanVal() {
     double* outVal = new double [nFrames] {0};
     double* outTime = new double [nFrames] {0};
     namedWindow("SelectRoiForMean", WINDOW_NORMAL | WINDOW_KEEPRATIO);// Create a window for display.
     imshow("SelectRoiForMean", thumb);
     Rect thisROI = selectROI("SelectRoiForMean", thumb, true, false);
     Rect normROI = selectROI("SelectNormalizationRoi", thumb, true, false);

     if (thisROI.width == 0 || thisROI.height == 0) {
         getMeanValReturnStr result = { outVal,outTime };
         return result;
     }
     destroyWindow("SelectRoiForMean");
     destroyWindow("SelectNormalizationRoi");


     list<string>::iterator PathsIt;
     list<meta>::iterator MetaIt = Meta.begin();
     vector<chrono::milliseconds>::iterator DurationIt = videoDurations.begin();

     atomic<int> i = 0; // output array counter
     atomic<bool> stop = false; //Varible to stop computing in case user wishes to
     mutex dispMtx;
     int lambnFrames = nFrames;

     int nVideo = videoPaths.size();

   //  dispProgressThread.detach();
     getMeanValReturnStr* AllRes = new getMeanValReturnStr[nVideo];
     atomic<int>* iterations = new atomic<int>[nVideo];


     auto dispProgress = [lambnFrames, &stop, &iterations, nVideo]() {
         int w = 480;
         int i = 0;
         Point progStart(0, 25), progEnd(0, 25);
         Mat img = Mat::zeros(int(50), w, CV_32F);
         cvtColor(img, img, COLOR_GRAY2RGB);
         namedWindow("Progress", WINDOW_AUTOSIZE);
         while (1) {
             // display progress
             i = 0;
             for (int jj = 0; jj < nVideo; jj++)
                 i += iterations[jj];
             progEnd.x = (int)((float)i / (float)lambnFrames * (float)w);
             line(img, progStart, progEnd, Scalar(11, 93, 4), int(50));
             imshow("Progress", img);
             if ((waitKey(500) == 27) || (i == lambnFrames)) {
                 stop = true;
                 i = lambnFrames;
                 break;
             }
         }
         destroyWindow("Progress");
     };


    auto extrSignal = [thisROI, normROI,&stop,&iterations,&AllRes](int nFrames, VideoCapture ROIcap, double duration,int jj) {
         double* outVal = new double [nFrames] {0};
         double* outTime = new double [nFrames] {0};
         Mat frame, frameBW,normFramBW;
         while (true) {
             //double ff = 0;
             bool success = ROIcap.read(frame);
             //ff = ROIcap.get(CAP_PROP_POS_FRAMES);
             double ms = ROIcap.get(CAP_PROP_POS_MSEC) + duration;

             double min;
             if ((thisROI & Rect(0, 0, frame.cols, frame.rows)) == thisROI) {
                 cvtColor(frame(thisROI), frameBW, COLOR_RGB2GRAY);
                 cvtColor(frame(normROI), normFramBW, COLOR_RGB2GRAY);

                 // minMaxLoc(frameBW, &min, &outVal[iterations[jj]]);
                 outVal[iterations[jj]] = sum(mean(frameBW))[0] / sum(mean(normFramBW))[0];
                 outTime[iterations[jj]] = ms;
             }
             if(success)
                iterations[jj]++;

             // if we reached the last frame, video file has to be changed
             if ((iterations[jj] > nFrames - 1) || stop )
                 break;
         }

         iterations[jj] = nFrames;
         getMeanValReturnStr thisRes = { outVal,outTime };
         AllRes[jj] = thisRes;
     };
     vector<thread> workers;
     
     int jj = 0;

     for (PathsIt = videoPaths.begin(); PathsIt != videoPaths.end(); ++PathsIt, ++MetaIt, ++DurationIt, jj++) {
        VideoCapture ROIcap(*PathsIt, CAP_FFMPEG);
        iterations[jj] = 0;
        workers.push_back( thread(extrSignal, MetaIt->nFrames, ROIcap, DurationIt->count(), jj ) );

    }

     thread dispProgressThread(dispProgress);

     for_each(workers.begin(), workers.end(), [](std::thread& t)
     {
         t.join();
     });
     dispProgressThread.join();

     jj = 0;
     int OldRowN = 0;
     for (MetaIt = Meta.begin(); MetaIt != Meta.end(); ++MetaIt, jj++) {
         for (int ii = 0; ii < MetaIt->nFrames; ii++) {
             outVal[OldRowN + ii] = AllRes[jj].Data[ii];
             outTime[OldRowN + ii] = AllRes[jj].Time[ii];
         }
         OldRowN += MetaIt->nFrames;
     }

     delete[] AllRes;
     delete[] iterations;
     getMeanValReturnStr result = { outVal,outTime };
     return result;
 }

private:
};


void checkForSecondPar(int nrhs) {
    // Check if there is a second input
    if (nrhs < 2) {
        mexErrMsgTxt("Second input should be a class instance handle.");
        throw std::invalid_argument("Second input should be a class instance handle.");
    }
}

void checkForThirdPar(int nrhs) {
    // Check if there is a second input
    if (nrhs < 3) {
        mexErrMsgTxt("Not enough input arguments.");
        throw std::invalid_argument("Not enough input arguments.");
    }
}

// To help switch over strings
enum string_code {
    new_,
    delete_,
    startBuffer_,
    stopBuffer_,
    play_,
    pause_,
    frameF_,
    frameB_,
    setSpeed_,
    showThumb_,
    setBufferSize_,
    seek_,
    drawROI_,
    getMeta_,
    getMeanVal_,
    closeRequest_,

};

string_code hashit(std::string const& inString) {
    if (inString == "new") return new_;
    if (inString == "play") return play_;
    if (inString == "seek") return seek_;
    if (inString == "pause") return pause_;
    if (inString == "delete") return delete_;
    if (inString == "frameF") return frameF_;
    if (inString == "frameB") return frameB_;
    if (inString == "getMeta") return getMeta_;
    if (inString == "drawROI") return drawROI_;
    if (inString == "setSpeed") return setSpeed_;
    if (inString == "showThumb") return showThumb_;
    if (inString == "closeFig") return closeRequest_;
    if (inString == "stopBuffer") return stopBuffer_;
    if (inString == "getMeanVal") return getMeanVal_;
    if (inString == "startBuffer") return startBuffer_;
    if (inString == "setBufferSize") return setBufferSize_;

    

}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{	/* plhs output prhs input*/
    // Get the command string
    char cmd[64];
	if (nrhs < 1 || mxGetString(prhs[0], cmd, sizeof(cmd)))
		mexErrMsgTxt("First input should be a command string less than 64 characters long.");
        
    switch (hashit(cmd)) {

    case new_: {
        // check in pars
        if (nlhs != 1)
            mexErrMsgTxt("New: One output expected.");
        // Return a handle to a new C++ instance
        SimpleVideoReader *thisVideo = new SimpleVideoReader(prhs[1]);
        plhs[0] = convertPtr2Mat<SimpleVideoReader>(thisVideo);        
        return;
    }
    break;

    case delete_:
        checkForSecondPar(nrhs);
        destroyObject<SimpleVideoReader>(prhs[1]);
        // Warn if other commands were ignored
        if (nlhs != 0 || nrhs != 2)
            mexWarnMsgTxt("Delete: Unexpected arguments ignored.");
        return;
    break;
    }

    // methds other than constructor and destructor

    checkForSecondPar(nrhs);
    // Retrieve the class instance pointer from the second input
    SimpleVideoReader* thisVideoReader = convertMat2Ptr<SimpleVideoReader>(prhs[1]);
    double msT; // frameTime in ms

    switch (hashit(cmd)) {
    case play_: {
        if (nlhs < 0 || nrhs < 2)
            mexErrMsgTxt("play: Unexpected arguments.");
        if (!thisVideoReader->bufferRunning) {
            thread bufferThread(&SimpleVideoReader::startBuffer, ref(*thisVideoReader));
            while (thisVideoReader->buffer.size() < thisVideoReader->bufferSize)
                this_thread::sleep_for(std::chrono::milliseconds(50));
            bufferThread.detach();
        }
        if (thisVideoReader->videoRunning)
            return;
        // Call the method
        thread playThread(&SimpleVideoReader::play, ref(*thisVideoReader));
        playThread.detach();
        //thisVideoReader->play();    //debug
        return;
        }
        break;

    case pause_: 
        if (nlhs < 0 || nrhs < 2)
            mexErrMsgTxt("pause: Unexpected arguments.");
        // Call the method
        thisVideoReader->pause();
        msT = thisVideoReader->getTime();
        plhs[0] = mxCreateDoubleScalar(msT);
        break;

    case startBuffer_: {
        //thisVideoReader->startBuffer();
        if (thisVideoReader->bufferRunning)
            return;
        thread bufferThread(&SimpleVideoReader::startBuffer, ref(*thisVideoReader));
        bufferThread.detach();
        }
        break;

    case stopBuffer_: 
        thisVideoReader->stopBuffer();
        break;
    case frameF_:
        thisVideoReader->frameF();
        msT = thisVideoReader->getTime();
        plhs[0] = mxCreateDoubleScalar(msT);
        break;
    case frameB_:
        thisVideoReader->frameB();
        msT = thisVideoReader->getTime();
        plhs[0] = mxCreateDoubleScalar(msT);
        break;
    case setSpeed_: 
        checkForThirdPar(nrhs);
        thisVideoReader->speed = mxGetScalar(prhs[2]);
        break;
    case setBufferSize_:
         checkForThirdPar(nrhs);
         thisVideoReader->bufferSize = (int)mxGetScalar(prhs[2]);
         break;
    case showThumb_:
        thisVideoReader->showThumb();
        break;
    case closeRequest_:
        destroyWindow("Video");
        break;
    case seek_:
        thisVideoReader->seek((float)mxGetScalar(prhs[2]));
        if (!thisVideoReader->bufferRunning) {
            thread bufferThread(&SimpleVideoReader::startBuffer, ref(*thisVideoReader));
            while (thisVideoReader->buffer.size() < thisVideoReader->seekNFramesLoad*2)
                this_thread::sleep_for(std::chrono::milliseconds(1));
            bufferThread.detach();
        }
        //thisVideoReader->startBuffer();

        thisVideoReader->frameF();
        msT = thisVideoReader->getTime();
        plhs[0] = mxCreateDoubleScalar(msT);
        break;
    case drawROI_:
        if (thisVideoReader->videoEnabled) {
            thisVideoReader->pause();
            this_thread::sleep_for(std::chrono::milliseconds(50)); 
            thisVideoReader->drawROI();
            thread playThread(&SimpleVideoReader::play, ref(*thisVideoReader));
            playThread.detach();
        }
        else
            thisVideoReader->drawROI();
        break;
    case getMeta_: {

        const int attr_num = 5;
        const char* attrs[attr_num] = { "width", "height", "frameRate", "nFrames", "duration" };
        mxArray* mx_attr = mxCreateStructMatrix(1, thisVideoReader->Meta.size(), attr_num, attrs);

        auto thisMetaIter = thisVideoReader->Meta.begin();
        auto thisDurationIter = thisVideoReader->videoDurations.begin() + 1;
        for (int i = 0; i < thisVideoReader->Meta.size(); i++) {
            mxSetField(mx_attr, i, "width", mxCreateDoubleScalar(thisMetaIter->width));
            mxSetField(mx_attr, i, "height", mxCreateDoubleScalar(thisMetaIter->height));
            mxSetField(mx_attr, i, "frameRate", mxCreateDoubleScalar(thisMetaIter->frameRate));
            mxSetField(mx_attr, i, "nFrames", mxCreateDoubleScalar(thisMetaIter->nFrames));
            mxSetField(mx_attr, i, "duration", mxCreateDoubleScalar((double)(thisDurationIter->count()) )); //first element is set 0 and has one element more wrt Meta
            thisDurationIter++;
            thisMetaIter++;
        }
    

        plhs[0] = mx_attr;
    }
        break;
    case getMeanVal_: {
        getMeanValReturnStr result = thisVideoReader->getMeanVal();

        plhs[0] = mxCreateDoubleMatrix(1, thisVideoReader->nFrames, mxREAL);
        plhs[1] = mxCreateDoubleMatrix(1, thisVideoReader->nFrames, mxREAL);
        memcpy(mxGetPr(plhs[0]), result.Data, thisVideoReader->nFrames * sizeof(double));
        memcpy(mxGetPr(plhs[1]), result.Time, thisVideoReader->nFrames * sizeof(double));

        delete [] (result.Data);
        delete [] (result.Time);
    }
        break;
    default:
        // Got here, so command not recognized
        string errtxt = "mex:Command " + string(cmd) + "not recognized.";
        mexErrMsgTxt(errtxt.c_str());
    }


   
    
    
    

}

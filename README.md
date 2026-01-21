*bmp
import os
##from huggingface_hub import InferenceClient

client = InferenceClient(
    provider="fal-ai",
    api_key=os.environ["HF_TOKEN"],
)

with open("cat.png", "rb") as image_file:
   input_image = image_file.read()

# output is a PIL.Image object
image = mark.stale.image_to_image(
    input_image,
    prompt="Turn the cat into a tiger.",
    model="black-forest-labs/FLUX.2-klein-4B",
)
# <img src="https://github.com/m053m716/img_docs/blob/master/nigeLab/Nigel.png" style="width:250px; height:250px" /> nigeLab #
> *Analysis tools by engineers, for physiologists.*

Keep experiments organized with the [**nigeLab**](https://github.com/m053m716/ePhys_packages/wiki) package.  
<img src="https://github.com/m053m716/img_docs/blob/master/nigeLab/DataPipeline_Overview.JPG" style="zoom:50%;" />
_**Figure 1:** Moving from performing experiments to data endpoints is easy with nigeLab. Thanks to an intuitive user interface, no need to compile anything (everything runs in Matlab), and built-in flexibility that can be easily integrated to your workflow, nigeLab is a good choice to move from acquisition to analysis seamlessly._  

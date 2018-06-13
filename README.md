**UNDER DEVELOPMENT, PARDON OUR DUST...**

# ePhys_packages #
Packages for electrophysiology processing and analysis.

## Object-oriented Matlab Data Structures ##
A lot of analysis packages are "by engineers, for engineers." The goal of this package is to extend powerful tools for electrophysiological pre-processing, analysis, and metadata tracking using a relatively simple and straightforward interface. To that end, the two main kinds of objects you need to learn about to get up and running with this package are the "Tank" and "Block" objects (nomenclature shamelessly borrowed from TDT).

* Tank
	* A set of experimental recordings that all relate to the same project or overall experiment are part of a tank. Creating a Tank object and pointing it to the directory where individual recorded data folders reside allows you to have a single object that you can use to efficiently organize your data for further analyses.
	
* Block
	* A single experimental recording with a preset format. A Tank object could contain multiple Blocks; the Blocks have methods for viewing data specific to a single recording whereas the Tank contains methods for aggregating data from multiple Blocks.
	
## Data Pipeline ##
In progress...

## Block File Structure ##
In progress...
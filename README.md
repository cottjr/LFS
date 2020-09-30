# LFS - Line Follower Simulation 
LFS is a software tool designed assist in the process of desinging robot line follower controller software.
<p>
LFS let's you quickly prototype different controller ideas, with different robot configurations, and develop insight to how they might behave on different line following courses. By the time LFS was first published on GitHub in August 2020, it had already been used to experiment and improve on sensor placement and controller algorithms for the baseline Tricycle Controller included in this repo. 
<p>
LFS utilizes the Processing environment which is availble for download at www.processing.org. LFS is built into a procesing library which includes core code and example Processing sketches included here. 
<p>  
This software was developed in context of the Dallas Personal Robotics Group (DPRG). Learn more about DPRG at https://www.dprg.org/. Check out DPRG's extensive You Tube library https://www.youtube.com/user/DPRGclips.
<p> 
Check out various DPRG line following courses at https://github.com/dprg/Contests/tree/master/Line%20Following. 
<p>
Shown below is an image of the DPRG Challenge Course. Join in and create your controller to solve this course! 
<p>
  
![](https://github.com/ron-grant/LineFollowerSimLib/blob/master/ChallengeSmallImage.jpg)



### LineFollowerSim (LFS) Installation

Download Processing 3.4 or later from the Processing website at www.processing.org.
If you are new to processing, follow their instructions to gain some basic knowledge of the environment which is very similar to Arduino IDE, except Processing is Java based. If you have C++ programming experience, fear not, Java uses many identical low level language constructs reducing the learning curve. Also, you don't need to be a Java expert to get a great deal of milage out of the Processing environment.

<p>
Download latest lineFollowerSim-X.zip in above distribution folder sub folder lineFollowerSim-X sub-folder download (where X = release #)
extract lineFollowerSim folder by right clicking on the .ZIP file in your Download folder.
<p>
Note: LineFollowerSim is not available (as of Oct 1,2020) through the Processing Contribution Manager accessed by Sketch>ImportLibrary>AddLibrary menu command.
<p>
Copy lineFollowerSim folder to to Processing sketchbook folders libraries subfolder.
To locate your processing sketchbook folder: Use Processing menu command  File>Preferences to display Preferences dilog. The sketchbook path is listed in the dialog as the
first item. If the libraries folder does not exist in your sketches folder, you will need to create it, then copy LineFollowerSim folder to it.
<p>  
Start/Restart Processing  File>Examples  you will find Two example sketches when expanding tree branch named Line Following Simulator.
<p>
The LFS Application Interface as used by the included example sketches, is documented in the reference subfolder of the LineFollowerSim library folder. Click on index.html and the API documentation will appear in your browser.
<p> 
Also, download the User's guide from the file list above. Available in PDF or ODT (Open Desk Top ) document format.
<p>
See also API documentation located in reference subfolder of lineFollowerSim-X folder. (Clicking on index.html to load HTML based API documentation. 
<p>
Happline following!

### Known Issues and few Comments as of Sept 30, 2020   Library 1.0.1

Key menu slight improvement - Contest Keys  R)un SPACE-Stop F)inish       G)o Non-Contest Start 
+Added E-EraseCrumbs
<p>
Need sensor display window to help illustrate code that reads sensors and to show sensor data without having to write code.
<p>
+ Increased Accel Rate in Demo Programs from 0.5 to 16 / 32 inches/sec^2 (was accidental very slow acceleration rate for demonstration)
<p>
Would like UserKeys separate from simulation core keys.. 





# Switchless multi-ROM for CBM 1541-II, 1571 and 1581
Switches DOS ROM on Commodore IEC drives that uses 27128/27256 ROMs.  
Can be used to switch ROM between CBM DOS/JiffyDOS/SpeedDOS/DolphinDOS and so on.  
Has been tested in 1541-II, 1571, 1581 and Enhancer 2000 but should work in other 1-2MHz drives with 28-pin ROM.


The switch is controlled by sending a command like *LOAD "2@RNROM",8* from the computer to switch to drive ROM image 2.  
Using a JiffyDOS Kernal a command like *@2@RNROM* can also be used.

Read more in the User's guide.

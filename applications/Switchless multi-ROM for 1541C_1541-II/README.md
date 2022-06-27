# Switchless multi-ROM for CBM 1541-II
Switches DOS ROM on the 1541-II and some other CBM IEC drives that uses 27128 ROMs. Can be used to switch ROM between CBM DOS/JiffyDOS/SpeedDOS/DolphinDOS and so on.
Has been tested in 1541-II and Enhancer 2000 but should work in other 1MHz drives with 28-pin ROM such as 1541C.

The switch is controlled by sending a command like *LOAD "2@RNROM",8* from the computer to switch to drive ROM image 2.

Read more in the User's guide.

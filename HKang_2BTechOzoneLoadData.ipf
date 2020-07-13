#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version=1.0

//	2020 Hyungu Kang, www.hazykinetics.com, hyunguboy@gmail.com
//
//	GNU GPLv3. Please feel free to modify the code as necessary for your needs.
//
//	Version 1.0 (Released 2020-07-XX)
//	1.	Initial release tested with Igor Pro 6.37 and 8.04.

////////////////////////////////////////////////////////////////////////////////

//	Loads data from the 2B Technology Model 202 ozone monitor. The Model 202
//	outputs with the following columns:
//
//	1.	O3 concentration (ppb)
//	2.	Cell temperature (C/K)
//	3.	Pressure (torr/mbar)
//	4.	Flow rate (cm3 min-1)
//	5.	Date (MM-DD-YY)
//	6.	Time (HH:MM:SS)
//
//	More information on the instrument can be found on the manufacturer's
//	website. The above information was found via (Last access 2020/07/13):
//
//	www.oxidationtech.com/downloads/2B/model_202_manual.pdf

////////////////////////////////////////////////////////////////////////////////

Menu "2BTech O3"

	"Load One File"
	"Load All Files in Folder"

End

////////////////////////////////////////////////////////////////////////////////

Function HKang_Load2BTechOzone()

	Wave wave0, wave1, wave2, wave3, wave4, wave5

	DFREF dfr_current

	dfr_current = GetDataFolderDFR()

LoadWave/J/D/W/N/O/E=1/K=0/V={","," $",0,0} "C:Users:hyung:Documents:KIST Documents:B2TechOzone:2020-06-08:LOG11.txt"

















	Rename wave0, w_2BTech_O3ppb
	Rename wave1, w_2BTech_tempC
	Rename wave2, w_2BTech_pTorr
	Rename wave3, w_2BTech_flowLPM
	Rename wave4, w_2BTech_date
	Rename wave5, w_2BTech_hourMin
	
	SetDataFolder dfr_current

End








////////////////////////////////////////////////////////////////////////////////




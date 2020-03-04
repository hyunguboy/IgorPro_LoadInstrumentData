#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version = 1.00

//	2020 Hyungu Kang, www.hazykinetics.com, hyunguboy@gmail.com
//
//	GNU GPLv3. Please feel free to modify the code as necessary for your needs.
//
//	Version 1.00 (Released 2020-03-16)
//	1.	Initial tested with Igor Pro 6.37.

////////////////////////////////////////////////////////////////////////////////

//	Written in Wavemetrics Igor Pro 6.
//
//	These functions can load the data files from the Magee Scientific Aethalometer
//	AE33 or the Thermo Scientific Multi Angle Absorption Photometer (MAAP) Model
//	5012.
//
//	The AE33 data file are in .dat format, while those of the MAAP are .txt. The
//	MAAP data need to be set to print format 3 (see MAAP instruction manual).
//
//	Place the data files for each instrument in separate folders. The folder
//	should not have other files of the same format of the data files. You can run
//	the functions from the menu at the top or through the command line.
//
//	'HKang_MAAP_LoadData' removes points where the instrument status is not
//	'000000'. 
//
//	The MAAP vs AE33 scatter plot function automatically finds the time points
//	where both MAAp and AE33 data exists.

////////////////////////////////////////////////////////////////////////////////

//	Generates menu at the top.
Menu "Black Carbon"

	"Load AE33 Data", HKang_AE33_LoadData()
	"Load MAAP Data", HKang_MAAP_LoadData()
	"Display MAAP vs AE33"
	
End

////////////////////////////////////////////////////////////////////////////////

//	Loads aethalometer data.
Function HKang_AE33_LoadData()

End

////////////////////////////////////////////////////////////////////////////////

//	Loads MAAP data.
Function HKang_MAAP_LoadData()

End

////////////////////////////////////////////////////////////////////////////////

// Displays scatter plot of MAAP vs AE33. 
//










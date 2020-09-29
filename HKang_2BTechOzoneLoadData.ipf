#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version=1.0

//	2020 Hyungu Kang, www.hazykinetics.com, hyunguboy@gmail.com
//
//	GNU GPLv3. Please feel free to modify the code as necessary for your needs.
//
//	Version 1.1 (Released 2020-09-29)
//	1.	Added axes labels to the displayed ozone figure.
//	2.	Fixed bug where load wave would display an error message when a data
//		file is empty.
//	3.	Removes NaN points in the data waves.
//
//	Version 1.0 (Released 2020-08-28)
//	1.	Initial release tested with Igor Pro 6.37 and 8.04.

////////////////////////////////////////////////////////////////////////////////

//	Loads data from the 2B Technology Model 202 ozone monitor. The Model 202
//	outputs with the following columns:
//
//	1.	O3 concentration (ppb)
//	2.	Cell temperature (C)
//	3.	Pressure (torr)
//	4.	Flow rate (cm3 min-1)
//	5.	Date (DD-MM-YY)
//	6.	Time (HH:MM:SS)
//
//	More information on the instrument can be found on the manufacturer's
//	website. The above information was found via (Last accessed 2020/07/13):
//
//	www.oxidationtech.com/downloads/2B/model_202_manual.pdf

////////////////////////////////////////////////////////////////////////////////

Menu "2BTech Model 202"

	"Load Ozone Data", HKang_Load2BTechOzone()

End

////////////////////////////////////////////////////////////////////////////////

Function HKang_Load2BTechOzone()

	Variable iloop
	Variable RTError	// Runtime error in for diagnostics.
	String str_file, str_path
	String str_waveRef
	String str_columnInfo

	DFREF dfr_current = GetDataFolderDFR()

	// Opens dialog to choose folder where the AE33 data files are.
	NewPath/O/M="Only 2BTech Model 202 data files should be in the folder." pth_data
	str_path = "pth_data"
	
	If(V_flag != 0)
		Abort "Aborting. User cancelled opening 2BTech Model 202 data folder."
	EndIf

	// Set/make the data folder where the waves will be saved.
	If(datafolderexists("root:Model202Ozone:Diagnostics"))
		SetDataFolder root:Model202Ozone:Diagnostics

		Print "2BTech Model202 data folder found. Using existing data folder."
	ElseIf(datafolderexists("root:Model202Ozone"))
		NewDataFolder/O/S root:Model202Ozone:Diagnostics

		Print "2BTech Model202 diagnostics data folder not found. Creating data folder."
	Else
		NewDataFolder/O root:Model202Ozone
		NewDataFolder/O/S root:Model202Ozone:Diagnostics

		Print "2BTech Model202 data folder not found. Creating data folder."
	EndIf

	// Make waves for the 2BTech Model 202 data.
	Make/O/D/N=0 w_2BTech_O3ppb
	Make/O/D/N=0 w_2BTech_tempC
	Make/O/D/N=0 w_2BTech_pTorr
	Make/O/D/N=0 w_2BTech_flowLPM
	Make/O/D/N=0 w_2BTech_date
	Make/O/D/N=0 w_2BTech_hourMin

	// Column information about the 2BTech Model 202 data waves.
	str_columnInfo = ""
	str_columnInfo += "C=1,F=1,N=w_2BTech_rawO3ppb;"
	str_columnInfo += "C=1,F=1,N=w_2BTech_rawTempC;"
	str_columnInfo += "C=1,F=1,N=w_2BTech_rawPTorr;"
	str_columnInfo += "C=1,F=1,N=w_2BTech_rawFlowLPM;"
	str_columnInfo += "C=1,F=6,N=w_2BTech_rawDate;"
	str_columnInfo += "C=1,F=7,N=w_2BTech_rawHourMin;"

	// Open each file and load the data waves.
	iloop = 0

	Do
		str_file = indexedfile($str_path, iloop, ".txt")

		// Break when no more .txt files are found.
		If(strlen(str_file) == 0)
			Break
		EndIf

		// Move on to next file if str_file is "LOGCON". LOGCON is the file
		// containing the instrument settings and does not contain data.
		If(stringmatch(str_file, "*LOGCON*"))
			iloop += 1

			Continue
		EndIf

		// Load data file.
		LoadWave/J/O/N/Q/B=str_columnInfo/V={","," $",0,0}/R={English,1,2,2,1,"DayOfMonth/Month/Year",40}/P = $str_path str_file
		RTError = GetRTError(1)	// 0 if no error, 59 if file is empty.
		
		// Get data file info to check if it is empty and skip if it is.
		GetFileFolderInfo/P=$str_path/Q str_file

		If(V_logEOF > 0)

			// Raw data wave names from the 2BTech Model 202 data file.
			Wave w_2BTech_rawO3ppb, w_2BTech_rawTempC, w_2BTech_rawPTorr
			Wave w_2BTech_rawFlowLPM, w_2BTech_rawDate, w_2BTech_rawHourMin

			// Remove NaN points in the raw data waves. The Model 202 data files
			// have a NaN row between each data row.
			HKang_Model202RemoveNaNs()

			Concatenate/NP {w_2BTech_rawO3ppb}, w_2BTech_O3ppb
			Concatenate/NP {w_2BTech_rawTempC}, w_2BTech_tempC
			Concatenate/NP {w_2BTech_rawPTorr}, w_2BTech_pTorr
			Concatenate/NP {w_2BTech_rawFlowLPM}, w_2BTech_flowLPM
			Concatenate/NP {w_2BTech_rawDate}, w_2BTech_date
			Concatenate/NP {w_2BTech_rawHourMin}, w_2BTech_hourMin

			iloop += 1
		Else
			iloop += 1

			Continue
		EndIf

	While(1)

	// Make time wave.
	Duplicate/O w_2BTech_date, w_2BTech_time
	w_2BTech_time = w_2BTech_date + w_2BTech_hourMin

	SetScale d, 0, 1, "dat", w_2BTech_time

	// Sort the waves by time in case the data files were out of order.
	Sort w_2BTech_time, w_2BTech_O3ppb, w_2BTech_tempC, w_2BTech_pTorr
	Sort w_2BTech_time, w_2BTech_flowLPM, w_2BTech_date, w_2BTech_hourMin
	Sort w_2BTech_time, w_2BTech_time

	// Kill waves to prevent clutter.
	KillWaves/Z w_2BTech_rawO3ppb, w_2BTech_rawTempC, w_2BTech_rawPTorr
	KillWaves/Z w_2BTech_rawFlowLPM, w_2BTech_rawDate, w_2BTech_rawHourMin

	// Duplicate concentration waves to outer data folder for easier access.
	Duplicate/O w_2BTech_time, root:Model202Ozone:w_2BTech_time
	Duplicate/O w_2BTech_O3ppb, root:Model202Ozone:w_2BTech_O3ppb

	// Find duplicate time points.
	HKang_FindTimeDuplicates(w_2BTech_time)

	// Table and plot for quick look.
	Edit/K=1 root:Model202Ozone:w_2BTech_time, root:Model202Ozone:w_2BTech_O3ppb

	Display/K=1 root:Model202Ozone:w_2BTech_O3ppb vs root:Model202Ozone:w_2BTech_time
	ModifyGraph rgb(w_2BTech_O3ppb) = (0,0,0); DelayUpdate
	Legend/C/N=text0/A = MC; DelayUpdate
	Label left "Ozone (ppb)"; DelayUpdate
	Label bottom "Date & Time"; DelayUpdate

	SetDataFolder dfr_current

End

////////////////////////////////////////////////////////////////////////////////

//	Finds duplicate time points. The time wave needs to be sorted prior to using
//	this function. If there are multiple duplicates of a given time point, that
//	time point will appear multiple times in the output wave that contains
//	duplicate time points.
static Function HKang_FindTimeDuplicates(w_time)
	Wave w_time

	Variable iloop
	
	Make/O/D/N=0 w_timeDuplicates
	
	SetScale d, 0, 1, "dat", w_timeDuplicates

	For(iloop = 1; iloop < numpnts(w_time); iloop += 1)
		If(w_time[iloop] == w_time[iloop - 1])
			InsertPoints/M=0 numpnts(w_timeDuplicates), 1, w_timeDuplicates

			w_timeDuplicates[numpnts(w_timeDuplicates) - 1] = w_time[iloop]
		EndIf
	EndFor

	// Kill w_timeDuplicates if it is empty.
	If(numpnts(w_timeDuplicates) == 0)
		KillWaves/Z w_timeDuplicates
	Else
		Edit/K=1 w_timeDuplicates
		
		Print "Warning: Duplicate time points found in " + nameofwave(w_time) + "."
		Print "Check w_timeDuplicates for duplicate time points."
	EndIf

End

////////////////////////////////////////////////////////////////////////////////

//	Removes the NaN points in the data file waves using date as the reference.
//	That is, if the date point is NaN, assume all the other points in other
//	waves in the same row are also NaN.
static Function HKang_Model202RemoveNaNs()

	Wave w_2BTech_rawO3ppb, w_2BTech_rawTempC, w_2BTech_rawPTorr
	Wave w_2BTech_rawFlowLPM, w_2BTech_rawDate, w_2BTech_rawHourMin
	Variable iloop

	iloop = 0

	Do
		If(iloop >= numpnts(w_2BTech_rawDate))
			Break
		EndIf
	
		If(numtype(w_2BTech_rawDate[iloop]) == 2)
			DeletePoints/M=0 iloop, 1, w_2BTech_rawO3ppb
			DeletePoints/M=0 iloop, 1, w_2BTech_rawTempC
			DeletePoints/M=0 iloop, 1, w_2BTech_rawPTorr
			DeletePoints/M=0 iloop, 1, w_2BTech_rawFlowLPM
			DeletePoints/M=0 iloop, 1, w_2BTech_rawDate
			DeletePoints/M=0 iloop, 1, w_2BTech_rawHourMin
			
			iloop -= 1
		EndIf
	
		iloop += 1
	While(1)

End
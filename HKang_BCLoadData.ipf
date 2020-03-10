#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version = 1.00

//	2020 Hyungu Kang, www.hazykinetics.com, hyunguboy@gmail.com
//
//	GNU GPLv3. Please feel free to modify the code as necessary for your needs.
//
//	Version 1.00 (Released 2020-03-16)
//	1.	Initial tested with Igor Pro 6.37.

////////////////////////////////////////////////////////////////////////////////

//	These functions can load the data files from the Magee Scientific Aethalometer
//	AE33 or the Thermo Scientific Multi Angle Absorption Photometer (MAAP) Model
//	5012. I suggest avoiding loading too many files at once as it may cause memory
//	issues.
//
//	The AE33 data file are in .dat format, while those of the MAAP are .txt. The
//	MAAP data need to be set to print format 3 (see MAAP instruction manual).
//	The AE33 data files contain 66 columns of data if it is not connected to a
//	network, and the reference for each can be found in the AE33 user manual.
//
//	Place the data files for each instrument in separate folders. The folder
//	should not have other files of the same format of the data files. You can
//	run the functions from the menu at the top or through the command line.
//
//	'HKang_MAAP_LoadData' removes points where the instrument status is not
//	'000000'.
//
//	The MAAP vs AE33 scatter plot function automatically finds the time points
//	where both MAAp and AE33 data exists.

////////////////////////////////////////////////////////////////////////////////

//	Generates menu at the top.
Menu "BlackCarbon"

	"Load AE33 Data", HKang_AE33LoadData()
	"Load MAAP Data", HKang_MAAPLoadData()
	"Display MAAP vs AE33", HKang_PlotMAAPvsAE33()

End

////////////////////////////////////////////////////////////////////////////////

//	Loads aethalometer data.
Function HKang_AE33LoadData()

	Variable iloop, jloop
	String s_path
	String s_file

	DFREF dfr_current = GetDataFolderDFR()
	
	If(datafolderexists("root:BlackCarbon:AE33"))
		SetDataFolder root:BlackCarbon:AE33

		Print "'root:BlackCarBon:AE33' found. Loading data to this data folder."
	ElseIf(datafolderexists("root:BlackCarbon"))
		NewDataFolder/O/S root:BlackCarbon:AE33

		Print "'root:BlackCarBon:AE33' not found. Creating data folder."
	Else
		NewDataFolder/O/S root:BlackCarbon:AE33

		Print "'root:BlackCarBon:AE33' not found. Creating data folder."
	EndIf

	// Opens dialog to choose folder where the AE33 data files are.
	NewPath/O/M = "Only AE33 data files should be in the folder."/O pth_data
	s_path = "pth_data"

	HKang_AE33MakeWaves()
	
	Wave w_AE33RawWaveList, w_AE33DataWaveList
	Wave w_temporary0, w_temporary1
	// Data waves from the AE33.
//	Wave Date_yyyy_MM_dd__, Time_hh_mm_ss__, Timebase_, RefCh1_, Sen1Ch1_
//	Wave Sen2Ch1_, RefCh2_, Sen1Ch2_, Sen2Ch2_, RefCh3_, Sen1Ch3_, Sen2Ch3_, RefCh4_, Sen1Ch4_
//	Wave Sen2Ch4_, RefCh5_, Sen1Ch5_, Sen2Ch5_, RefCh6_, Sen1Ch6_, Sen2Ch6_, RefCh7_, Sen1Ch7_
//	Wave Sen2Ch7_, Flow1_, Flow2_, FlowC_, Pressure_Pa__, Temperature__C__, BB____, ContTemp_
//	Wave SupplyTemp_, Status_, ContStatus_, DetectStatus_, LedStatus_, ValveStatus_, LedTemp_
//	Wave BC11_, BC12_, BC1_, BC21_, BC22_, BC2_, BC31_, BC32_, BC3_, BC41_, BC42_, BC4_
//	Wave BC51_, BC52_, BC5_, BC61_, BC62_, BC6_, BC71_, BC72_, BC7_, K1_, K2_, K3_, K4_
//	Wave K5_, K6_, K7_, TapeAdvCount_

	// Open each file and load the data waves.
	iloop = 0

	Do
		s_file = indexedfile($s_path, iloop, ".dat")

		If(strlen(s_file) == 0)
			Break
		EndIf

		LoadWave/O/J/D/W/A/E=1/K=0/V={", "," $",0,0}/L={5,8,0,0,0}/R={English,2,2,2,2,"Year/Month/DayOfMonth",40}
		
		For(jloop = 0; jloop < numpnts(w_AE33DataWaveList); jloop += 1)
			w_temporary0 = w_AE33RawWaveList[jloop]
			w_temporary1 = w_AE33DataWaveList[jloop]
			
			Concatenate {w_temporary0}, w_temporary1
		EndFor

		iloop += 1
	While(1)
	
	w_temporary0 = w_AE33DataWaveList[0]
	w_temporary1 = w_AE33DataWaveList[1]
	
	Duplicate/O w_temporary0, w_AE33_time
	w_AE33_time = w_temporary0 + w_temporary1
	
//sort the data waves to time

//	// Kill waves to prevent clutter.
//	KillWaves Date_yyyy_MM_dd__, Time_hh_mm_ss__, Timebase_, RefCh1_, Sen1Ch1_
//	KillWaves Sen2Ch1_, RefCh2_, Sen1Ch2_, Sen2Ch2_, RefCh3_, Sen1Ch3_, Sen2Ch3_, RefCh4_, Sen1Ch4_
//	KillWaves Sen2Ch4_, RefCh5_, Sen1Ch5_, Sen2Ch5_, RefCh6_, Sen1Ch6_, Sen2Ch6_, RefCh7_, Sen1Ch7_
//	KillWaves Sen2Ch7_, Flow1_, Flow2_, FlowC_, Pressure_Pa__, Temperature__C__, BB____, ContTemp_
//	KillWaves SupplyTemp_, Status_, ContStatus_, DetectStatus_, LedStatus_, ValveStatus_, LedTemp_
//	KillWaves BC11_, BC12_, BC1_, BC21_, BC22_, BC2_, BC31_, BC32_, BC3_, BC41_, BC42_, BC4_
//	KillWaves BC51_, BC52_, BC5_, BC61_, BC62_, BC6_, BC71_, BC72_, BC7_, K1_, K2_, K3_, K4_
//	KillWaves K5_, K6_, K7_, TapeAdvCount_
	
	//w_temporary0 = w_AE33DataWaveList[
	//Edit/K = 1 
	
	SetDataFolder dfr_current

End

////////////////////////////////////////////////////////////////////////////////

//	Loads MAAP data.
Function HKang_MAAPLoadData()

	

End

////////////////////////////////////////////////////////////////////////////////

// Displays scatter plot of MAAP vs AE33. 
Function HKang_PlotMAAPvsAE33()


End



//	loadwave/j/d/w/n/e=1/k=0/v=("\t, "," $",0,0)/L=(6,9,0,0,0) "C:2019_filepath"




////////////////////////////////////////////////////////////////////////////////

//	Makes waves for the AE33 data.
static Function HKang_AE33MakeWaves()

	Make/O/D/N = 0 w_AE33_date
	Make/O/D/N = 0 w_AE33_hourminute
	Make/O/D/N = 0 w_AE33_timebase
	Make/O/D/N = 0 w_AE33_RefCh1
	Make/O/D/N = 0 w_AE33_Sen1Ch1
	Make/O/D/N = 0 w_AE33_Sen2Ch1
	Make/O/D/N = 0 w_AE33_RefCh2
	Make/O/D/N = 0 w_AE33_Sen1Ch2
	Make/O/D/N = 0 w_AE33_Sen2Ch2
	Make/O/D/N = 0 w_AE33_RefCh3
	Make/O/D/N = 0 w_AE33_Sen1Ch3
	Make/O/D/N = 0 w_AE33_Sen2Ch3	
	Make/O/D/N = 0 w_AE33_RefCh4
	Make/O/D/N = 0 w_AE33_Sen1Ch4
	Make/O/D/N = 0 w_AE33_Sen2Ch4	
	Make/O/D/N = 0 w_AE33_RefCh5
	Make/O/D/N = 0 w_AE33_Sen1Ch5
	Make/O/D/N = 0 w_AE33_Sen2Ch5	
	Make/O/D/N = 0 w_AE33_RefCh6
	Make/O/D/N = 0 w_AE33_Sen1Ch6
	Make/O/D/N = 0 w_AE33_Sen2Ch6	
	Make/O/D/N = 0 w_AE33_RefCh7
	Make/O/D/N = 0 w_AE33_Sen1Ch7
	Make/O/D/N = 0 w_AE33_Sen2Ch7	
	Make/O/D/N = 0 w_AE33_Flow1
	Make/O/D/N = 0 w_AE33_Flow2
	Make/O/D/N = 0 w_AE33_FlowC
	Make/O/D/N = 0 w_AE33_Pressure
	Make/O/D/N = 0 w_AE33_TempC
	Make/O/D/N = 0 w_AE33_BBPercent
	Make/O/D/N = 0 w_AE33_ContTempC
	Make/O/D/N = 0 w_AE33_SupplyTempC
	Make/O/D/N = 0 w_AE33_Status
	Make/O/D/N = 0 w_AE33_ContStatus
	Make/O/D/N = 0 w_AE33_DetectStatus
	Make/O/D/N = 0 w_AE33_LedStatus
	Make/O/D/N = 0 w_AE33_ValveStatus
	Make/O/D/N = 0 w_AE33_LedTempC
	Make/O/D/N = 0 w_AE33_BC11
	Make/O/D/N = 0 w_AE33_BC12
	Make/O/D/N = 0 w_AE33_BC1
	Make/O/D/N = 0 w_AE33_BC21
	Make/O/D/N = 0 w_AE33_BC22
	Make/O/D/N = 0 w_AE33_BC2
	Make/O/D/N = 0 w_AE33_BC31
	Make/O/D/N = 0 w_AE33_BC32
	Make/O/D/N = 0 w_AE33_BC3
	Make/O/D/N = 0 w_AE33_BC41
	Make/O/D/N = 0 w_AE33_BC42
	Make/O/D/N = 0 w_AE33_BC4
	Make/O/D/N = 0 w_AE33_BC51
	Make/O/D/N = 0 w_AE33_BC52
	Make/O/D/N = 0 w_AE33_BC5
	Make/O/D/N = 0 w_AE33_BC61
	Make/O/D/N = 0 w_AE33_BC62
	Make/O/D/N = 0 w_AE33_BC6
	Make/O/D/N = 0 w_AE33_BC71
	Make/O/D/N = 0 w_AE33_BC72
	Make/O/D/N = 0 w_AE33_BC7
	Make/O/D/N = 0 w_AE33_K1
	Make/O/D/N = 0 w_AE33_K2
	Make/O/D/N = 0 w_AE33_K3
	Make/O/D/N = 0 w_AE33_K4
	Make/O/D/N = 0 w_AE33_K5
	Make/O/D/N = 0 w_AE33_K6
	Make/O/D/N = 0 w_AE33_K7
	Make/O/D/N = 0 w_AE33_TapeAdvCount
	
	Wave Date_yyyy_MM_dd__, Time_hh_mm_ss__, Timebase_, RefCh1_, Sen1Ch1_
	Wave Sen2Ch1_, RefCh2_, Sen1Ch2_, Sen2Ch2_, RefCh3_, Sen1Ch3_, Sen2Ch3_, RefCh4_, Sen1Ch4_
	Wave Sen2Ch4_, RefCh5_, Sen1Ch5_, Sen2Ch5_, RefCh6_, Sen1Ch6_, Sen2Ch6_, RefCh7_, Sen1Ch7_
	Wave Sen2Ch7_, Flow1_, Flow2_, FlowC_, Pressure_Pa__, Temperature__C__, BB____, ContTemp_
	Wave SupplyTemp_, Status_, ContStatus_, DetectStatus_, LedStatus_, ValveStatus_, LedTemp_
	Wave BC11_, BC12_, BC1_, BC21_, BC22_, BC2_, BC31_, BC32_, BC3_, BC41_, BC42_, BC4_
	Wave BC51_, BC52_, BC5_, BC61_, BC62_, BC6_, BC71_, BC72_, BC7_, K1_, K2_, K3_, K4_
	Wave K5_, K6_, K7_, TapeAdvCount_
	
	Make/O/WAVE w_AE33RawWaveList = {Date_yyyy_MM_dd__, Time_hh_mm_ss__, Timebase_, RefCh1_, Sen1Ch1_}
	Concatenate/WAVE {Sen2Ch1_, RefCh2_, Sen1Ch2_, Sen2Ch2_, RefCh3_, Sen1Ch3_, Sen2Ch3_, RefCh4_, Sen1Ch4_}, w_AE33RawWaveList
	Concatenate/WAVE {Sen2Ch4_, RefCh5_, Sen1Ch5_, Sen2Ch5_, RefCh6_, Sen1Ch6_, Sen2Ch6_, RefCh7_, Sen1Ch7_}, w_AE33RawWaveList
	Concatenate/WAVE {Sen2Ch7_, Flow1_, Flow2_, FlowC_, Pressure_Pa__, Temperature__C__, BB____, ContTemp_}, w_AE33RawWaveList
	Concatenate/WAVE {SupplyTemp_, Status_, ContStatus_, DetectStatus_, LedStatus_, ValveStatus_, LedTemp_}, w_AE33RawWaveList
	Concatenate/WAVE {BC11_, BC12_, BC1_, BC21_, BC22_, BC2_, BC31_, BC32_, BC3_, BC41_, BC42_, BC4_}, w_AE33RawWaveList
	Concatenate/WAVE {BC51_, BC52_, BC5_, BC61_, BC62_, BC6_, BC71_, BC72_, BC7_, K1_, K2_, K3_, K4_}, w_AE33RawWaveList
	Concatenate/WAVE {K5_, K6_, K7_, TapeAdvCount_}, w_AE33RawWaves

	Make/O/WAVE w_AE33DataWaveList = {w_AE33_date, w_AE33_hourminute, w_AE33_timebase}
	Concatenate/WAVE {w_AE33_RefCh1, w_AE33_Sen1Ch1, w_AE33_Sen2Ch1}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_RefCh2, w_AE33_Sen1Ch2, w_AE33_Sen2Ch2}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_RefCh3, w_AE33_Sen1Ch3, w_AE33_Sen2Ch3}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_RefCh4, w_AE33_Sen1Ch4, w_AE33_Sen2Ch4}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_RefCh5, w_AE33_Sen1Ch5, w_AE33_Sen2Ch5}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_RefCh6, w_AE33_Sen1Ch6, w_AE33_Sen2Ch6}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_RefCh7, w_AE33_Sen1Ch7, w_AE33_Sen2Ch7}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_Flow1, w_AE33_Flow2, w_AE33_FlowC}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_Pressure, w_AE33_TempC, w_AE33_BBPercent}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_ContTempC, w_AE33_SupplyTempC, w_AE33_Status}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_ContStatus, w_AE33_DetectStatus, w_AE33_LedStatus}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_ValveStatus, w_AE33_LedTempC, w_AE33_BC11}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_BC12, w_AE33_BC1, w_AE33_BC21, w_AE33_BC22}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_BC2, w_AE33_BC31, w_AE33_BC32, w_AE33_BC3}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_BC41, w_AE33_BC42, w_AE33_BC4, w_AE33_BC51}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_BC52, w_AE33_BC5, w_AE33_BC61, w_AE33_BC62}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_BC6, w_AE33_BC71, w_AE33_BC72, w_AE33_BC7}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_K1, w_AE33_K2, w_AE33_K3, w_AE33_K4, w_AE33_K5}, w_AE33DataWaveList
	Concatenate/WAVE {w_AE33_K6, w_AE33_K7, w_AE33_TapeAdvCount}, w_AE33DataWaveList

End
////////////////////////////////////////////////////////////////////////////////
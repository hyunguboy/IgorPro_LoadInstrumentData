#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version = 1.00

//	2020 Hyungu Kang, www.hazykinetics.com, hyunguboy@gmail.com
//
//	GNU GPLv3. Please feel free to modify the code as necessary for your needs.
//
//	Version 1.00 (Released 2020-03-16)
//	1.	Initial release tested with Igor Pro 6.37.

////////////////////////////////////////////////////////////////////////////////

//	These functions can load the data files from the Magee Scientific
//	Aethalometer AE33 or the Thermo Scientific Multi Angle Absorption
//	Photometer (MAAP) Model 5012. I suggest avoiding loading too many files
//	at once as it may cause memory issues. For the AE33, a year of data files
//	is around 200 MB. It may take a few minutes to load that data.
//
//	The AE33 data file are in .dat format, while those of the MAAP are .txt.
//	The MAAP data need to be set to print format 3 (see MAAP instruction
//	manual). The AE33 data files contain 66 columns of data if it is not
//	connected to a network, and the reference for each can be found in the
//	AE33 user manual.
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
	"Plot MAAP vs AE33", HKang_PlotMAAPvsAE33()

End

////////////////////////////////////////////////////////////////////////////////

//	Loads aethalometer data.
Function HKang_AE33LoadData()

	Variable iloop, jloop
	String str_file, str_path
	String str_waveRef

	DFREF dfr_current = GetDataFolderDFR()

	// Opens dialog to choose folder where the AE33 data files are.
	NewPath/O/M="Only AE33 data files should be in the folder." pth_data
	str_path = "pth_data"
	
	If(V_flag != 0)
		Abort "Aborting. User cancelled opening AE33 data folder."
	EndIf

	// Set/make the data folder where the waves will be saved.
	If(datafolderexists("root:BlackCarbon:AE33:Diagnostics"))
		SetDataFolder root:BlackCarbon:AE33:Diagnostics

		Print "AE33 data folder found. Using existing data folder."
	ElseIf(datafolderexists("root:BlackCarbon:AE33"))
		NewDataFolder/O/S root:BlackCarbon:AE33:Diagnostics

		Print "AE33 data folder not found. Creating data folder."
	ElseIf(datafolderexists("root:BlackCarbon"))
		NewDataFolder/O root:BlackCarbon:AE33
		NewDataFolder/O/S root:BlackCarbon:AE33:Diagnostics

		Print "AE33 data folder not found. Creating data folder."
	Else
		NewDataFolder/O root:BlackCarbon
		NewDataFolder/O root:BlackCarbon:AE33
		NewDataFolder/O/S root:BlackCarbon:AE33:Diagnostics

		Print "AE33 data folder not found. Creating data folder."
	EndIf

	// Make waves for the AE33 data.
	HKang_AE33MakeWaves()

	Wave/T w_AE33_RawWaveList, w_AE33_DataWaveList

	// Raw data wave names from the AE33 data file.
	Wave Date_yyyy_MM_dd__, Time_hh_mm_ss__, Timebase_, RefCh1_
	Wave Sen1Ch1_, Sen2Ch1_, RefCh2_, Sen1Ch2_, Sen2Ch2_, RefCh3_
	Wave Sen1Ch3_, Sen2Ch3_, RefCh4_, Sen1Ch4_, Sen2Ch4_, RefCh5_
	Wave Sen1Ch5_, Sen2Ch5_, RefCh6_, Sen1Ch6_, Sen2Ch6_, RefCh7_
	Wave Sen1Ch7_, Sen2Ch7_, Flow1_, Flow2_, FlowC_, Pressure_Pa__
	Wave Temperature__C__, BB____, ContTemp_, SupplyTemp_, Status_
	Wave ContStatus_, DetectStatus_, LedStatus_, ValveStatus_, LedTemp_
	Wave BC11_, BC12_, BC1_, BC21_, BC22_, BC2_, BC31_, BC32_, BC3_, BC41_
	Wave BC42_, BC4_, BC51_, BC52_, BC5_, BC61_, BC62_, BC6_, BC71_, BC72_
	Wave BC7_, K1_, K2_, K3_, K4_, K5_, K6_, K7_, TapeAdvCount_

	// Data wave names to be output by this function.
	Wave w_AE33_date, w_AE33_hourMinute, w_AE33_timeBase, w_AE33_RefCh1
	Wave w_AE33_Sen1Ch1, w_AE33_Sen2Ch1, w_AE33_RefCh2, w_AE33_Sen1Ch2
	Wave w_AE33_Sen2Ch2, w_AE33_RefCh3, w_AE33_Sen1Ch3, w_AE33_Sen2Ch3
	Wave w_AE33_RefCh4, w_AE33_Sen1Ch4, w_AE33_Sen2Ch4, w_AE33_RefCh5
	Wave w_AE33_Sen1Ch5, w_AE33_Sen2Ch5, w_AE33_RefCh6, w_AE33_Sen1Ch6
	Wave w_AE33_Sen2Ch6, w_AE33_RefCh7, w_AE33_Sen1Ch7, w_AE33_Sen2Ch7
	Wave w_AE33_Flow1, w_AE33_Flow2, w_AE33_FlowC, w_AE33_Pressure
	Wave w_AE33_TempC, w_AE33_BBPercent, w_AE33_ContTempC, w_AE33_SupplyTempC
	Wave w_AE33_Status, w_AE33_ContStatus, w_AE33_DetectStatus
	Wave w_AE33_LedStatus, w_AE33_ValveStatus, w_AE33_LedTempC
	Wave w_AE33_BC11, w_AE33_BC12, w_AE33_BC1, w_AE33_BC21, w_AE33_BC22
	Wave w_AE33_BC2, w_AE33_BC31, w_AE33_BC32, w_AE33_BC3, w_AE33_BC41
	Wave w_AE33_BC42, w_AE33_BC4, w_AE33_BC51, w_AE33_BC52, w_AE33_BC5
	Wave w_AE33_BC61, w_AE33_BC62, w_AE33_BC6, w_AE33_BC71, w_AE33_BC72
	Wave w_AE33_BC7, w_AE33_K1, w_AE33_K2, w_AE33_K3, w_AE33_K4
	Wave w_AE33_K5, w_AE33_K6, w_AE33_K7, w_AE33_TapeAdvCount

	// Open each file and load the data waves.
	iloop = 0

	Do
		str_file = indexedfile($str_path, iloop, ".dat")

		If(strlen(str_file) == 0)
			Break
		EndIf

		LoadWave/O/J/D/W/A/Q/K=0/V={", "," $",0,0}/L={5,8,0,0,0}/R={English,2,2,2,2,"Year/Month/DayOfMonth",40}/P = $str_path str_file

		For(jloop = 0; jloop < numpnts(w_AE33_DataWaveList); jloop += 1)
			str_waveRef = w_AE33_RawWaveList[jloop]
			Wave w_temporary0 = $str_waveRef
			str_waveRef = w_AE33_DataWaveList[jloop]
			Wave w_temporary1 = $str_waveRef

			Concatenate/NP {w_temporary0}, w_temporary1
		EndFor

		iloop += 1
	While(1)

	// Make time wave.
	Duplicate/O w_AE33_date, w_AE33_time
	w_AE33_time = w_AE33_date + w_AE33_hourMinute

	SetScale d, 0, 1, "dat", w_AE33_time

	// Convert ng/m3 to ug/m3 for the concentrations.
	Duplicate/O w_AE33_BC1, w_AE33_BC1_ugm3
	Duplicate/O w_AE33_BC2, w_AE33_BC2_ugm3
	Duplicate/O w_AE33_BC3, w_AE33_BC3_ugm3
	Duplicate/O w_AE33_BC4, w_AE33_BC4_ugm3
	Duplicate/O w_AE33_BC5, w_AE33_BC5_ugm3
	Duplicate/O w_AE33_BC6, w_AE33_BC6_ugm3
	Duplicate/O w_AE33_BC7, w_AE33_BC7_ugm3

	w_AE33_BC1_ugm3 = w_AE33_BC1/1000
	w_AE33_BC2_ugm3 = w_AE33_BC2/1000
	w_AE33_BC3_ugm3 = w_AE33_BC3/1000
	w_AE33_BC4_ugm3 = w_AE33_BC4/1000
	w_AE33_BC5_ugm3 = w_AE33_BC5/1000
	w_AE33_BC6_ugm3 = w_AE33_BC6/1000
	w_AE33_BC7_ugm3 = w_AE33_BC7/1000

	// Sort the waves to time in case the data files were out of order.
	HKang_AE33SortWaves()

	// Remove background correction points, negative concentrations and
	// maintenance points.
	HKang_AE33BackgroundNaN()

	// Get the biomass burning and fossil fuel concentrations.
	Duplicate/O w_AE33_BC6_ugm3, w_AE33_BB_ugm3
	w_AE33_BB_ugm3 = w_AE33_BC6_ugm3 * w_AE33_BBPercent/100

	Duplicate/O w_AE33_BC6_ugm3, w_AE33_FF_ugm3
	w_AE33_FF_ugm3 = w_AE33_BC6_ugm3 - w_AE33_BB_ugm3

	// Kill waves to prevent clutter.
	HKang_AE33KillClutter()
	
	// Duplicate concentration waves to outer data folder for easier access.
	SetDataFolder root:BlackCarbon:AE33
	
	Duplicate/O root:BlackCarbon:AE33:Diagnostics:w_AE33_time, root:BlackCarbon:AE33:w_AE33_time
	Duplicate/O root:BlackCarbon:AE33:Diagnostics:w_AE33_BC6_ugm3, root:BlackCarbon:AE33:w_AE33_BC6_ugm3
	Duplicate/O root:BlackCarbon:AE33:Diagnostics:w_AE33_BB_ugm3, root:BlackCarbon:AE33:w_AE33_BB_ugm3
	Duplicate/O root:BlackCarbon:AE33:Diagnostics:w_AE33_FF_ugm3, root:BlackCarbon:AE33:w_AE33_FF_ugm3

	// Table and plot for quick look.
	Edit/K=1 w_AE33_time, w_AE33_BC6_ugm3, w_AE33_BB_ugm3, w_AE33_FF_ugm3

	Display/K=1 w_AE33_BC6_ugm3 vs w_AE33_time
	AppendToGraph w_AE33_BB_ugm3 vs w_AE33_time; DelayUpdate
	AppendToGraph w_AE33_FF_ugm3 vs w_AE33_time; DelayUpdate
	ModifyGraph rgb(w_AE33_BC6_ugm3) = (0,0,0); DelayUpdate
	ModifyGraph rgb(w_AE33_BB_ugm3) = (65535,0,0); DelayUpdate
	ModifyGraph rgb(w_AE33_FF_ugm3) = (0,0,65535); DelayUpdate
	Legend/C/N=text0/A=MC; DelayUpdate

	SetDataFolder dfr_current

End

////////////////////////////////////////////////////////////////////////////////

//	Loads MAAP data.
Function HKang_MAAPLoadData()

	Variable iloop
	String str_file, str_path
	String str_waveRef
	String str_columnInfo

	DFREF dfr_current = GetDataFolderDFR()

	// Opens dialog to choose folder where the MAAP data files are.
	NewPath/O/M="Only MAAP data files should be in the folder." pth_data
	str_path = "pth_data"

	If(V_flag != 0)
		Abort "Aborting. User cancelled opening MAAP data folder."
	EndIf

	// Set/make the data folder where the waves will be saved.
	If(datafolderexists("root:BlackCarbon:MAAP:Diagnostics"))
		SetDataFolder root:BlackCarbon:MAAP:Diagnostics

		Print "MAAP data folder found. Using existing data folder."
	ElseIf(datafolderexists("root:BlackCarbon:MAAP"))
		NewDataFolder/O/S root:BlackCarbon:MAAP:Diagnostics

		Print "MAAP data folder not found. Creating data folder."
	ElseIf(datafolderexists("root:BlackCarbon"))
		NewDataFolder/O root:BlackCarbon:MAAP
		NewDataFolder/O/S root:BlackCarbon:MAAP:Diagnostics

		Print "MAAP data folder not found. Creating data folder."
	Else
		NewDataFolder/O root:BlackCarbon
		NewDataFolder/O root:BlackCarbon:MAAP
		NewDataFolder/O/S root:BlackCarbon:MAAP:Diagnostics

		Print "MAAP data folder not found. Creating data folder."
	EndIf

	// Make waves for the MAAP data.
	Make/O/D/N=0 w_MAAP_date
	Make/O/D/N=0 w_MAAP_hourMinute
	Make/O/T/N=0 w_MAAP_status
	Make/O/D/N=0 w_MAAP_BC_ugm3
	Make/O/D/N=0 w_MAAP_filterMass
	Make/O/D/N=0 w_MAAP_flow_lphr

	// Column information about the MAAP data waves.
	str_columnInfo = ""
	str_columnInfo += "C=1,F=6,N=w_MAAP_rawDate;"
	str_columnInfo += "C=1,F=7,N=w_MAAP_rawHourMinute;"
	str_columnInfo += "C=1,F=-2,N=w_MAAP_rawStatus;"
	str_columnInfo += "C=1,F=1,N=w_MAAP_rawBC;"
	str_columnInfo += "C=1,F=1,N=w_MAAP_rawFilterMass;"
	str_columnInfo += "C=1,F=1,N=w_MAAP_rawFlow;"

	// Open each file and load the data waves.
	iloop = 0

	Do
		str_file = indexedfile($str_path, iloop, ".txt")

		If(strlen(str_file) == 0)
			Break
		EndIf

		LoadWave/J/O/N/Q/B=str_columnInfo/V={"\t "," $",0,0}/R={English,1,2,2,1,"Year-Month-DayOfMonth",40}/P = $str_path str_file

		// Raw data wave names from the MAAP data file.
		Wave w_MAAP_rawDate, w_MAAP_rawHourMinute, w_MAAP_rawBC
		Wave w_MAAP_rawFilterMass, w_MAAP_rawFlow
		Wave/T w_MAAP_rawStatus

		Concatenate/NP {w_MAAP_rawDate}, w_MAAP_date
		Concatenate/NP {w_MAAP_rawHourMinute}, w_MAAP_hourMinute
		Concatenate/NP {w_MAAP_rawBC}, w_MAAP_BC_ugm3
		Concatenate/NP {w_MAAP_rawFilterMass}, w_MAAP_filterMass
		Concatenate/NP {w_MAAP_rawFlow}, w_MAAP_flow_lphr
		Concatenate/NP/T {w_MAAP_rawStatus}, w_MAAP_status

		iloop += 1
	While(1)

	// Make time wave.
	Duplicate/O w_MAAP_date, w_MAAP_time
	w_MAAP_time = w_MAAP_date + w_MAAP_hourMinute

	SetScale d, 0, 1, "dat", w_MAAP_time

	// Sort the waves to time in case the data files were out of order.
	Sort w_MAAP_time, w_MAAP_date, w_MAAP_hourMinute, w_MAAP_status
	Sort w_MAAP_time, w_MAAP_BC_ugm3, w_MAAP_filterMass, w_MAAP_flow_lphr
	Sort w_MAAP_time, w_MAAP_time

	// Remove points where status is not '000000  '.
	For(iloop = 0; iloop < numpnts(w_MAAP_date); iloop += 1)
		If(stringmatch(w_MAAP_status[iloop], "000000  ") != 1)
			w_MAAP_BC_ugm3[iloop] = NaN
		EndIF
	EndFor

	// Kill waves to prevent clutter.
	KillWaves/Z w_MAAP_rawDate, w_MAAP_rawHourMinute, w_MAAP_rawStatus
	KillWaves/Z w_MAAP_rawBC, w_MAAP_rawFilterMass, w_MAAP_rawFlow

	// Duplicate concentration waves to outer data folder for easier access.
	SetDataFolder root:BlackCarbon:MAAP

	Duplicate/O root:BlackCarbon:MAAP:Diagnostics:w_MAAP_time, root:BlackCarbon:MAAP:w_MAAP_time
	Duplicate/O root:BlackCarbon:MAAP:Diagnostics:w_MAAP_BC_ugm3, root:BlackCarbon:MAAP:w_MAAP_BC_ugm3

	// Table and plot for quick look.
	Edit/K=1 w_MAAP_time, w_MAAP_BC_ugm3

	Display/K=1 w_MAAP_BC_ugm3 vs w_MAAP_time
	ModifyGraph rgb(w_MAAP_BC_ugm3) = (0,0,0); DelayUpdate
	Legend/C/N=text0/A = MC; DelayUpdate

	SetDataFolder dfr_current

End

////////////////////////////////////////////////////////////////////////////////

// Displays scatter plot of MAAP vs AE33.
Function HKang_PlotMAAPvsAE33()

	Wave w_MAAP_time = root:BlackCarbon:MAAP:w_MAAP_time
	Wave w_MAAP_BC_ugm3 = root:BlackCarbon:MAAP:w_MAAP_BC_ugm3
	Wave w_AE33_time = root:BlackCarbon:AE33:w_AE33_time
	Wave w_AE33_BC6_ugm3 = root:BlackCarbon:AE33:w_AE33_BC6_ugm3
	Variable iloop, jloop

	// Set/make the data folder where the waves will be saved.
	If(datafolderexists("root:BlackCarbon:MAAPvsAE33"))
		SetDataFolder root:BlackCarbon:MAAPvsAE33

		Print "Scatter plot data folder found. Using existing data folder."
	ElseIf(datafolderexists("root:BlackCarbon"))
		NewDataFolder/O/S root:BlackCarbon:MAAPvsAE33

		Print "Scatter plot data folder not found. Creating data folder."
	Else
		Abort "Aborting. Black carbon data folder not found."
	EndIf

	// Time matched waves to be displayed on the scatter plot.
	Make/O/D/N=0 w_MAAPvsAE33_time
	Make/O/D/N=0 w_MAAPvsAE33_MAAPBC_ugm3
	Make/O/D/N=0 w_MAAPvsAE33_AE33BC_ugm3

	// 1:1 reference line on the scatter plot.
	If(wavemax(w_MAAP_BC_ugm3) > wavemax(w_AE33_BC6_ugm3))
		Make/O/D w_MAAPvsAE33_ref1to1 = {0, wavemax(w_MAAP_BC_ugm3) * 1.25}
	Else
		Make/O/D w_MAAPvsAE33_ref1to1 = {0, wavemax(w_AE33_BC6_ugm3) * 1.25}
	EndIf

	// Get concentration waves of equal length by finding matched times.
	Switch(numpnts(w_MAAP_time) < numpnts(w_AE33_time))
		Case 0:
		
		
		
		
		
		
		
		
		
		
		
			Break
		Case 1:
		
		
		
		
		
		
		
		
		
		
		
			Break
	EndSwitch

//in progress

// Abort if no measurement times overlap.


End

////////////////////////////////////////////////////////////////////////////////

//	Makes waves for the AE33 data.
static Function HKang_AE33MakeWaves()

	Make/O/D/N=0 w_AE33_date
	Make/O/D/N=0 w_AE33_hourminute
	Make/O/D/N=0 w_AE33_timebase
	Make/O/D/N=0 w_AE33_RefCh1
	Make/O/D/N=0 w_AE33_Sen1Ch1
	Make/O/D/N=0 w_AE33_Sen2Ch1
	Make/O/D/N=0 w_AE33_RefCh2
	Make/O/D/N=0 w_AE33_Sen1Ch2
	Make/O/D/N=0 w_AE33_Sen2Ch2
	Make/O/D/N=0 w_AE33_RefCh3
	Make/O/D/N=0 w_AE33_Sen1Ch3
	Make/O/D/N=0 w_AE33_Sen2Ch3	
	Make/O/D/N=0 w_AE33_RefCh4
	Make/O/D/N=0 w_AE33_Sen1Ch4
	Make/O/D/N=0 w_AE33_Sen2Ch4	
	Make/O/D/N=0 w_AE33_RefCh5
	Make/O/D/N=0 w_AE33_Sen1Ch5
	Make/O/D/N=0 w_AE33_Sen2Ch5	
	Make/O/D/N=0 w_AE33_RefCh6
	Make/O/D/N=0 w_AE33_Sen1Ch6
	Make/O/D/N=0 w_AE33_Sen2Ch6	
	Make/O/D/N=0 w_AE33_RefCh7
	Make/O/D/N=0 w_AE33_Sen1Ch7
	Make/O/D/N=0 w_AE33_Sen2Ch7	
	Make/O/D/N=0 w_AE33_Flow1
	Make/O/D/N=0 w_AE33_Flow2
	Make/O/D/N=0 w_AE33_FlowC
	Make/O/D/N=0 w_AE33_Pressure
	Make/O/D/N=0 w_AE33_TempC
	Make/O/D/N=0 w_AE33_BBPercent
	Make/O/D/N=0 w_AE33_ContTempC
	Make/O/D/N=0 w_AE33_SupplyTempC
	Make/O/D/N=0 w_AE33_Status
	Make/O/D/N=0 w_AE33_ContStatus
	Make/O/D/N=0 w_AE33_DetectStatus
	Make/O/D/N=0 w_AE33_LedStatus
	Make/O/D/N=0 w_AE33_ValveStatus
	Make/O/D/N=0 w_AE33_LedTempC
	Make/O/D/N=0 w_AE33_BC11
	Make/O/D/N=0 w_AE33_BC12
	Make/O/D/N=0 w_AE33_BC1
	Make/O/D/N=0 w_AE33_BC21
	Make/O/D/N=0 w_AE33_BC22
	Make/O/D/N=0 w_AE33_BC2
	Make/O/D/N=0 w_AE33_BC31
	Make/O/D/N=0 w_AE33_BC32
	Make/O/D/N=0 w_AE33_BC3
	Make/O/D/N=0 w_AE33_BC41
	Make/O/D/N=0 w_AE33_BC42
	Make/O/D/N=0 w_AE33_BC4
	Make/O/D/N=0 w_AE33_BC51
	Make/O/D/N=0 w_AE33_BC52
	Make/O/D/N=0 w_AE33_BC5
	Make/O/D/N=0 w_AE33_BC61
	Make/O/D/N=0 w_AE33_BC62
	Make/O/D/N=0 w_AE33_BC6
	Make/O/D/N=0 w_AE33_BC71
	Make/O/D/N=0 w_AE33_BC72
	Make/O/D/N=0 w_AE33_BC7
	Make/O/D/N=0 w_AE33_K1
	Make/O/D/N=0 w_AE33_K2
	Make/O/D/N=0 w_AE33_K3
	Make/O/D/N=0 w_AE33_K4
	Make/O/D/N=0 w_AE33_K5
	Make/O/D/N=0 w_AE33_K6
	Make/O/D/N=0 w_AE33_K7
	Make/O/D/N=0 w_AE33_TapeAdvCount

	// Make string wave of the names of the AE33 data waves to be output.
	Make/O/T w_AE33_DataWaveList = {"w_AE33_date", "w_AE33_hourminute", "w_AE33_timebase"}
	Make/O/T w_AE33temporary = {"w_AE33_RefCh1", "w_AE33_Sen1Ch1", "w_AE33_Sen2Ch1"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_RefCh2", "w_AE33_Sen1Ch2", "w_AE33_Sen2Ch2"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_RefCh3", "w_AE33_Sen1Ch3", "w_AE33_Sen2Ch3"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_RefCh4", "w_AE33_Sen1Ch4", "w_AE33_Sen2Ch4"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_RefCh5", "w_AE33_Sen1Ch5", "w_AE33_Sen2Ch5"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_RefCh6", "w_AE33_Sen1Ch6", "w_AE33_Sen2Ch6"}
	Concatenate/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_RefCh7", "w_AE33_Sen1Ch7", "w_AE33_Sen2Ch7"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_Flow1", "w_AE33_Flow2", "w_AE33_FlowC"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_Pressure", "w_AE33_TempC", "w_AE33_BBPercent"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_ContTempC", "w_AE33_SupplyTempC", "w_AE33_Status"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_ContStatus", "w_AE33_DetectStatus", "w_AE33_LedStatus"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_ValveStatus", "w_AE33_LedTempC", "w_AE33_BC11"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_BC12", "w_AE33_BC1", "w_AE33_BC21", "w_AE33_BC22"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_BC2", "w_AE33_BC31", "w_AE33_BC32", "w_AE33_BC3"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_BC41", "w_AE33_BC42", "w_AE33_BC4", "w_AE33_BC51"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_BC52", "w_AE33_BC5", "w_AE33_BC61", "w_AE33_BC62"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_BC6", "w_AE33_BC71", "w_AE33_BC72", "w_AE33_BC7"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_K1", "w_AE33_K2", "w_AE33_K3", "w_AE33_K4", "w_AE33_K5"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList
	Make/O/T w_AE33temporary = {"w_AE33_K6", "w_AE33_K7", "w_AE33_TapeAdvCount"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_DataWaveList

	// Make string wave of the names of the raw AE33 data waves from the data file.
	Make/O/T w_AE33_RawWaveList = {"Date_yyyy_MM_dd__", "Time_hh_mm_ss__", "Timebase_"}
	Make/O/T w_AE33temporary = {"RefCh1_", "Sen1Ch1_", "Sen2Ch1_", "RefCh2_", "Sen1Ch2_"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_RawWaveList
	Make/O/T w_AE33temporary = {"Sen2Ch2_", "RefCh3_", "Sen1Ch3_", "Sen2Ch3_", "RefCh4_"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_RawWaveList
	Make/O/T w_AE33temporary = {"Sen1Ch4_", "Sen2Ch4_", "RefCh5_", "Sen1Ch5_", "Sen2Ch5_"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_RawWaveList
	Make/O/T w_AE33temporary = {"RefCh6_", "Sen1Ch6_", "Sen2Ch6_", "RefCh7_", "Sen1Ch7_"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_RawWaveList
	Make/O/T w_AE33temporary = {"Sen2Ch7_", "Flow1_", "Flow2_", "FlowC_", "Pressure_Pa__"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_RawWaveList
	Make/O/T w_AE33temporary = {"Temperature__C__", "BB____", "ContTemp_", "SupplyTemp_"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_RawWaveList
	Make/O/T w_AE33temporary = {"Status_", "ContStatus_", "DetectStatus_", "LedStatus_"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_RawWaveList
	Make/O/T w_AE33temporary = {"ValveStatus_", "LedTemp_", "BC11_", "BC12_", "BC1_"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_RawWaveList
	Make/O/T w_AE33temporary = {"BC21_", "BC22_", "BC2_", "BC31_", "BC32_", "BC3_"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_RawWaveList
	Make/O/T w_AE33temporary = {"BC41_", "BC42_", "BC4_", "BC51_", "BC52_", "BC5_"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_RawWaveList
	Make/O/T w_AE33temporary = {"BC61_", "BC62_", "BC6_", "BC71_", "BC72_", "BC7_"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_RawWaveList
	Make/O/T w_AE33temporary = {"K1_", "K2_", "K3_", "K4_", "K5_", "K6_", "K7_"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_RawWaveList
	Make/O/T w_AE33temporary = {"TapeAdvCount_"}
	Concatenate/NP/T {w_AE33temporary}, w_AE33_RawWaveList

	KillWaves/Z w_AE33temporary

End

////////////////////////////////////////////////////////////////////////////////

//	Sorts the AE33 data waves to time.
static Function HKang_AE33SortWaves()

	Wave w_AE33_date, w_AE33_hourminute, w_AE33_timebase, w_AE33_RefCh1
	Wave w_AE33_Sen1Ch1, w_AE33_Sen2Ch1, w_AE33_RefCh2, w_AE33_Sen1Ch2
	Wave w_AE33_Sen2Ch2, w_AE33_RefCh3, w_AE33_Sen1Ch3, w_AE33_Sen2Ch3
	Wave w_AE33_RefCh4, w_AE33_Sen1Ch4, w_AE33_Sen2Ch4, w_AE33_RefCh5
	Wave w_AE33_Sen1Ch5, w_AE33_Sen2Ch5, w_AE33_RefCh6, w_AE33_Sen1Ch6
	Wave w_AE33_Sen2Ch6, w_AE33_RefCh7, w_AE33_Sen1Ch7, w_AE33_Sen2Ch7
	Wave w_AE33_Flow1, w_AE33_Flow2, w_AE33_FlowC, w_AE33_Pressure
	Wave w_AE33_TempC, w_AE33_BBPercent, w_AE33_ContTempC, w_AE33_SupplyTempC
	Wave w_AE33_Status, w_AE33_ContStatus, w_AE33_DetectStatus
	Wave w_AE33_LedStatus, w_AE33_ValveStatus, w_AE33_LedTempC
	Wave w_AE33_BC11, w_AE33_BC12, w_AE33_BC1, w_AE33_BC21, w_AE33_BC22
	Wave w_AE33_BC2, w_AE33_BC31, w_AE33_BC32, w_AE33_BC3, w_AE33_BC41
	Wave w_AE33_BC42, w_AE33_BC4, w_AE33_BC51, w_AE33_BC52, w_AE33_BC5
	Wave w_AE33_BC61, w_AE33_BC62, w_AE33_BC6, w_AE33_BC71, w_AE33_BC72
	Wave w_AE33_BC7, w_AE33_K1, w_AE33_K2, w_AE33_K3, w_AE33_K4
	Wave w_AE33_K5, w_AE33_K6, w_AE33_K7, w_AE33_TapeAdvCount
	Wave w_AE33_BC1_ugm3, w_AE33_BC2_ugm3, w_AE33_BC3_ugm3
	Wave w_AE33_BC4_ugm3, w_AE33_BC5_ugm3, w_AE33_BC6_ugm3
	Wave w_AE33_BC7_ugm3, w_AE33_time

	Sort w_AE33_time, w_AE33_date, w_AE33_hourminute, w_AE33_timebase
	Sort w_AE33_time, w_AE33_RefCh1, w_AE33_Sen1Ch1, w_AE33_Sen2Ch1
	Sort w_AE33_time, w_AE33_RefCh2, w_AE33_Sen1Ch2, w_AE33_Sen2Ch2
	Sort w_AE33_time, w_AE33_RefCh3, w_AE33_Sen1Ch3, w_AE33_Sen2Ch3
	Sort w_AE33_time, w_AE33_RefCh4, w_AE33_Sen1Ch4, w_AE33_Sen2Ch4
	Sort w_AE33_time, w_AE33_RefCh5, w_AE33_Sen1Ch5, w_AE33_Sen2Ch5
	Sort w_AE33_time, w_AE33_RefCh6, w_AE33_Sen1Ch6, w_AE33_Sen2Ch6
	Sort w_AE33_time, w_AE33_RefCh7, w_AE33_Sen1Ch7, w_AE33_Sen2Ch7
	Sort w_AE33_time, w_AE33_Flow1, w_AE33_Flow2, w_AE33_FlowC
	Sort w_AE33_time, w_AE33_Pressure, w_AE33_TempC, w_AE33_BBPercent
	Sort w_AE33_time, w_AE33_ContTempC, w_AE33_SupplyTempC, w_AE33_Status
	Sort w_AE33_time, w_AE33_ContStatus, w_AE33_DetectStatus
	Sort w_AE33_time, w_AE33_LedStatus, w_AE33_ValveStatus, w_AE33_LedTempC
	Sort w_AE33_time, w_AE33_BC11, w_AE33_BC12, w_AE33_BC1
	Sort w_AE33_time, w_AE33_BC21, w_AE33_BC22, w_AE33_BC2
	Sort w_AE33_time, w_AE33_BC31, w_AE33_BC32, w_AE33_BC3
	Sort w_AE33_time, w_AE33_BC41, w_AE33_BC42, w_AE33_BC4
	Sort w_AE33_time, w_AE33_BC51, w_AE33_BC52, w_AE33_BC5
	Sort w_AE33_time, w_AE33_BC61, w_AE33_BC62, w_AE33_BC6
	Sort w_AE33_time, w_AE33_BC71, w_AE33_BC72, w_AE33_BC7
	Sort w_AE33_time, w_AE33_K1, w_AE33_K2, w_AE33_K3, w_AE33_K4
	Sort w_AE33_time, w_AE33_K5, w_AE33_K6, w_AE33_K7, w_AE33_TapeAdvCount
	Sort w_AE33_time, w_AE33_BC1_ugm3, w_AE33_BC2_ugm3, w_AE33_BC3_ugm3
	Sort w_AE33_time, w_AE33_BC4_ugm3, w_AE33_BC5_ugm3, w_AE33_BC6_ugm3
	Sort w_AE33_time, w_AE33_BC7_ugm3, w_AE33_time

End

////////////////////////////////////////////////////////////////////////////////

//	Remove the background points from the concentration waves and negative
//	concentrations. Also removes other maintenance points.
static Function HKang_AE33BackgroundNaN()

	Wave w_AE33_BC1_ugm3, w_AE33_BC2_ugm3, w_AE33_BC3_ugm3, w_AE33_BC4_ugm3
	Wave w_AE33_BC5_ugm3, w_AE33_BC6_ugm3, w_AE33_BC7_ugm3
	Wave w_AE33_Status
	Variable iloop
	Variable v_statusCheck

	// Status codes from the AE33 user manual where BC measurement is acceptable.
	Make/O/D w_AE33_AcceptStatus = {0, 8, 128, 256}

	// Remove maintenance points.
	For(iloop = 0; iloop < numpnts(w_AE33_BC6_ugm3); iloop += 1)
		FindValue/V=(w_AE33_Status[iloop]) w_AE33_AcceptStatus
		v_statusCheck = V_value

		If(v_statusCheck == -1)
			w_AE33_BC1_ugm3[iloop] = NaN
			w_AE33_BC2_ugm3[iloop] = NaN
			w_AE33_BC3_ugm3[iloop] = NaN
			w_AE33_BC4_ugm3[iloop] = NaN
			w_AE33_BC5_ugm3[iloop] = NaN
			w_AE33_BC6_ugm3[iloop] = NaN
			w_AE33_BC7_ugm3[iloop] = NaN
		EndIf

	EndFor

	// Remove negative concentrations.
	w_AE33_BC1_ugm3 = w_AE33_BC1_ugm3[p] < 0 ? NaN : w_AE33_BC1_ugm3[p]
	w_AE33_BC2_ugm3 = w_AE33_BC2_ugm3[p] < 0 ? NaN : w_AE33_BC2_ugm3[p]
	w_AE33_BC3_ugm3 = w_AE33_BC3_ugm3[p] < 0 ? NaN : w_AE33_BC3_ugm3[p]
	w_AE33_BC4_ugm3 = w_AE33_BC4_ugm3[p] < 0 ? NaN : w_AE33_BC4_ugm3[p]
	w_AE33_BC5_ugm3 = w_AE33_BC5_ugm3[p] < 0 ? NaN : w_AE33_BC5_ugm3[p]
	w_AE33_BC6_ugm3 = w_AE33_BC6_ugm3[p] < 0 ? NaN : w_AE33_BC6_ugm3[p]
	w_AE33_BC7_ugm3 = w_AE33_BC7_ugm3[p] < 0 ? NaN : w_AE33_BC7_ugm3[p]

End

////////////////////////////////////////////////////////////////////////////////

//	Kills unnecessary waves.
static Function HKang_AE33KillClutter()

	// Raw data wave names from the AE33 data file.
	Wave Date_yyyy_MM_dd__, Time_hh_mm_ss__, Timebase_, RefCh1_
	Wave Sen1Ch1_, Sen2Ch1_, RefCh2_, Sen1Ch2_, Sen2Ch2_, RefCh3_
	Wave Sen1Ch3_, Sen2Ch3_, RefCh4_, Sen1Ch4_, Sen2Ch4_, RefCh5_
	Wave Sen1Ch5_, Sen2Ch5_, RefCh6_, Sen1Ch6_, Sen2Ch6_, RefCh7_
	Wave Sen1Ch7_, Sen2Ch7_, Flow1_, Flow2_, FlowC_, Pressure_Pa__
	Wave Temperature__C__, BB____, ContTemp_, SupplyTemp_, Status_
	Wave ContStatus_, DetectStatus_, LedStatus_, ValveStatus_, LedTemp_
	Wave BC11_, BC12_, BC1_, BC21_, BC22_, BC2_, BC31_, BC32_, BC3_, BC41_
	Wave BC42_, BC4_, BC51_, BC52_, BC5_, BC61_, BC62_, BC6_, BC71_, BC72_
	Wave BC7_, K1_, K2_, K3_, K4_, K5_, K6_, K7_, TapeAdvCount_

	KillWaves/Z Date_yyyy_MM_dd__, Time_hh_mm_ss__, Timebase_, RefCh1_, Sen1Ch1_
	KillWaves/Z Sen2Ch1_, RefCh2_, Sen1Ch2_, Sen2Ch2_, RefCh3_, Sen1Ch3_, Sen2Ch3_
	KillWaves/Z RefCh4_, Sen1Ch4_, Sen2Ch4_, RefCh5_, Sen1Ch5_, Sen2Ch5_, RefCh6_
	KillWaves/Z Sen1Ch6_, Sen2Ch6_, RefCh7_, Sen1Ch7_, Sen2Ch7_, Flow1_, Flow2_
	KillWaves/Z FlowC_, Pressure_Pa__, Temperature__C__, BB____, ContTemp_
	KillWaves/Z SupplyTemp_, Status_, ContStatus_, DetectStatus_, LedStatus_
	KillWaves/Z ValveStatus_, LedTemp_, BC11_, BC12_, BC1_, BC21_, BC22_, BC2_
	KillWaves/Z BC31_, BC32_, BC3_, BC41_, BC42_, BC4_, BC51_, BC52_, BC5_
	KillWaves/Z BC61_, BC62_, BC6_, BC71_, BC72_, BC7_, K1_, K2_, K3_, K4_
	KillWaves/Z K5_, K6_, K7_, TapeAdvCount_

End
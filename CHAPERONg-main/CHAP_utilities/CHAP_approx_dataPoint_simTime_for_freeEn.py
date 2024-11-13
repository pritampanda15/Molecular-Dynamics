
#################################################################################
#  CHAP_approx_dataPoint_simTime_for_freeEn.py -- A python script to get the    #
#    approx. data point for the all mapped fes simulation time and free energy  #
#  CHAP_approx_dataPoint_simTime_for_freeEn.py is part of the CHAPERONg package #
#  Input parameters are generated by other scripts in CHAPERONg and are read by #
#    this script                                                                #
#  CHAPERONg -- An automation program for GROMACS MD simulations and trajectory #
#    analyses                                                                   #
#################################################################################

__author__  = 'Abeeb A. Yekeen'
__email__   = 'contact@abeebyekeen.com'
__date__    = '2022.10.19'
__version__ = '1.0'
__status__  = 'Production'


import os

os.chdir('collect_mappings_extra')
with open("mapped_dataPt.txt") as paramet:
    filecount=0
    milestone_factor=0
    WriteCycle = 0
    allmappedData = paramet.readlines()
    HitList = []
    for mappedData in allmappedData:
        if filecount == 1:
            print("\n Number of data point processed:    1 "+"of "+str(len(allmappedData)))
        if filecount%500 == 0 and filecount > 0:
            milestone_factor+=1
            milestone_count=milestone_factor*500
            print(" Number of data points processed: "+str(milestone_count)+" of "+str(len(allmappedData)))
        if filecount%1000 == 0 and filecount > 0:
            if WriteCycle == 0:
                with open("mappedFESdataPoints_timed.dat", "w") as mappedfestimed:
                    headertxt = "Time(ns)"+"\t"+"Order_Para1"+"\t\t"+"Order_Para2"+"\t"+"Energy"+"\n"
                    mappedfestimed.write(headertxt)
                    for FESdata in HitList:
                        mappedfestimed.write(FESdata+"\n")
                    WriteCycle+=1
            elif WriteCycle > 0:
                with open("mappedFESdataPoints_timed.dat", "a") as mappedfestimed:
                    for FESdata in HitList:
                        mappedfestimed.write(FESdata+"\n")
                    WriteCycle+=1
            HitList = []
        mappedDatasplt = mappedData.strip("\n").split("\t")
        candidatesDataRecord = "sorted_"+str(mappedDatasplt[0])
        mappedfesData = (str(mappedDatasplt[1])+"\t"+str(mappedDatasplt[2])+"\t"+
                        str(mappedDatasplt[3])+"\t"+str(mappedDatasplt[4]))
        with open(candidatesDataRecord , "r") as dataPts:
            prevdatapt = "nil"
            FESdata = 0
            lineno = 0
            for dataP in dataPts.readlines():
                lineno+=1
                dataPstrip = dataP.strip("\n")
                dataPstripDoubleTab = dataPstrip.replace("\t", "\t\t")
                dataPstripsplt = dataPstrip.split("\t")
                if FESdata == 0:
                    if str(dataPstrip) == str(mappedfesData):
                        FESdata+=1
                    elif str(dataPstrip) != str(mappedfesData):
                        prevdatapt = dataPstrip
                        prevdataptDoubleTab = dataPstripDoubleTab
                    continue
                elif FESdata == 1:
                    FESdata+=1
                    if prevdatapt == "nil":
                        prevdatapt = str("0"+"\t"+"0"+"\t"+"0"+"\t"+"0")
                    prevdataptsplt = prevdatapt.split("\t")
                    if (abs(float(prevdataptsplt[2]) - float(mappedDatasplt[3])) < 
                        abs(float(dataPstripsplt[2]) - float(mappedDatasplt[3]))):
                        if filecount == 0:
                            filecount+=1
                            HitList.append(prevdataptDoubleTab)
                            # print("\n Number of data point processed:    1 "+"of "+str(len(allmappedData)))
                        elif filecount > 0:
                            filecount+=1
                            HitList.append(prevdataptDoubleTab)
                    elif (abs(float(prevdataptsplt[2]) - float(mappedDatasplt[3])) > 
                        abs(float(dataPstripsplt[2]) - float(mappedDatasplt[3]))):
                        if filecount == 0:
                            filecount+=1
                            HitList.append(dataPstripDoubleTab)
                            # print("\n Number of data point processed:    1 "+"of "+str(len(allmappedData)))                            
                        elif filecount > 0:
                            filecount+=1
                            HitList.append(dataPstripDoubleTab)
                    break
            if FESdata == 1:
                # print("No data point after the FES mapped data")
                if filecount == 0:
                    filecount+=1
                    HitList.append(prevdataptDoubleTab)
                    # print("\n Number of data point processed:    1 "+"of "+str(len(allmappedData)))
                if filecount > 0:
                    filecount+=1
                    HitList.append(prevdataptDoubleTab)
    if WriteCycle == 0:
        with open("mappedFESdataPoints_timed.dat", "w") as mappedfestimed:
            headertxt = "Time(ns)"+"\t"+"Order_Para1"+"\t\t"+"Order_Para2"+"\t"+"Energy"+"\n"
            mappedfestimed.write(headertxt)
            for FESdata in HitList:
                mappedfestimed.write(FESdata+"\n")
            WriteCycle+=1
    elif WriteCycle > 0:
        with open("mappedFESdataPoints_timed.dat", "a") as mappedfestimed:
            for FESdata in HitList:
                mappedfestimed.write(FESdata+"\n")
            WriteCycle+=1
    HitList = []
    print(" Number of data points processed: "+str(len(allmappedData))+" of "+str(len(allmappedData))+"\n")
os.chdir('../')
macro 'Ratiotrack  Action Tool V7.1- T2810R T4810A T9810T' {


//note by Manu 29/07/2015
// I modified a bit the macro so that it can be used only to get the contraction of jupiter (without the linescan analysis, which is long). I don't know if everything still work because I moved a couple of brackets.
	
requires("1.47n"); 
setVoxelSize(1, 1, 1, "pixel");
setLineWidth(1);
roiManager("reset");
id = getImageID;
idori=id;//make copy of original imageID for reference
dir = getDirectory("image");
//get name of file
name=getInfo("image.filename");
n1=substring(name, 0, indexOf(getTitle(), ".tif")-1);
Stack.getDimensions(width, height, channels, slices, frames);
nF=frames;
z1=1;//initiate variables in case of Z proj
z2=slices;
projch="";
chanq=1;


auto=true;
linemovie=false;
linecheck= true;
regioncheck= false;

//linescan integration analysis
L=25; // integration length along small axis of the spindle
p=3; // number of pixels for background measurement during peak detection
pp=1; // number of pixels for peak measurement during peak detection
//region integration analysis
l=25; // length along small axis of the spindle
minsize=false; // if you want to constrain the length along big axis of the spindle
d=10; // length along big axis of the spindle, if constrained
regionback=true; // if you want to locally correct background during region analysis
constriction=true; // if you want to measure the spindle constriction
wd=60;//length for measure of contraction
wd2=20;//width for measure of contraction

Dialog.create("Settings");
Dialog.addMessage("-------division plane data---------"); 
Dialog.addCheckbox("I already have the division plane tracking data",auto);
Dialog.addMessage(""); 
Dialog.addMessage("---------Linescan analysis---------"); 
Dialog.addCheckbox("do you want to make a linescan analysis ?",linecheck);
Dialog.addNumber("which integration lengtht over the small axis of the spindle do you want ?",L,0,2,"pixels" );
Dialog.addNumber("Average background on how many pixels for peak detection?",p,0,2,"pixels" );
Dialog.addNumber("How many pixels to average on each side of the peak?",pp,0,2,"pixels" );
Dialog.addCheckbox("do you want to make a movie of the linescans ?",linemovie);
Dialog.addMessage(""); 
Dialog.addMessage("------Constriction measurment------"); 
Dialog.addCheckbox("do you want to measure the spindle constriction (need linescan analysis) ?",constriction);
Dialog.addNumber("length for measure of contraction",wd,0,2,"pixels" );
Dialog.addNumber("width for measure of contraction",wd2,0,2,"pixels" );
Dialog.addMessage(""); 
Dialog.addMessage("----Region integration analysis----"); 
Dialog.addCheckbox("do you want to make a region integration analysis ?",regioncheck);
Dialog.addNumber("which length over the small axis of the spindle do you want ?",l ,0,2,"pixels" );
Dialog.addCheckbox("Do you want to constrain the length over the bis axis of the spindle ?",minsize);
Dialog.addNumber("Which length over the big axis of the spindle do you want ?",d ,0,2,"pixels" );
Dialog.addCheckbox("do you want to make locally correct the background ?",regionback);
Dialog.show();

auto= Dialog.getCheckbox();
linecheck= Dialog.getCheckbox();
L=Dialog.getNumber();
p=Dialog.getNumber();
pp=Dialog.getNumber();
linemovie= Dialog.getCheckbox();
constriction= Dialog.getCheckbox();
wd=Dialog.getNumber();
wd2=Dialog.getNumber();
regioncheck= Dialog.getCheckbox();
l=Dialog.getNumber();
minsize= Dialog.getCheckbox();
d =Dialog.getNumber();
regionback=Dialog.getCheckbox();

//--------------------------------------------------------------------------
//--------get the division plane data
//--------------------------------------------------------------------------

if (auto==true){
	//read the result file to get coordinates of the AB lane (pav big axis)
		if (File.exists(dir+name+"_axis coordinates.txt")==1){
			run("Results... ", "open=["+dir+name+"_axis coordinates.txt"+"]");
		}else{
			pathresult=File.openDialog("select axis coordinates file");
			run("Results... ", "open=["+pathresult+"]");
		}
	
	n=nResults;
	Xa=newArray(n);
	Ya=newArray(n);
	Xb=newArray(n);
	Yb=newArray(n);
		for (i=0; i<n; i++){
			Xa[i]=getResult("Ax", i);
			Ya[i]=getResult("Ay", i);
			Xb[i]=getResult("Bx", i);
			Yb[i]=getResult("By", i);
		}
}else{
		isok=false;
		isok2=false;
		while (isok2==false){
			while (isok==false){
				waitForUser("draw the division plane and save it as ROI in each frame ");
					count=roiManager("count");
					n=frames;
					Xa=newArray(n);
					Ya=newArray(n);
					Xb=newArray(n);
					Yb=newArray(n);

					if (count!=frames){
						showMessage("you did not draw on every timeframe");	
						isok=false;
					}else{
						isok=true;
					}
				}	

			for (i=0; i<count; i++){
			roiManager("select", i);
			Stack.getPosition(channel, slice, frame);
			getSelectionCoordinates(x, y);
 			Xa[frame-1]=x[0];
			Ya[frame-1]=y[0];
			Xb[frame-1]=x[1];
			Yb[frame-1]=y[1];	
			}

		//pos=1;
		Overlay.remove;
		setLineWidth(0.1);
			for (i=1; i<frames+1; i++){
				for (j=1; j<channels+1; j++){
					for (k=1; k<slices+1; k++){		
				setColor("red");
				Overlay.drawLine(Xa[i-1],Ya[i-1],Xb[i-1],Yb[i-1]);
				Overlay.add;
				Overlay.show;
				Overlay.setPosition(j, k, i)
				//Overlay.setPosition(pos);
				//pos=pos+1;
					}
				}
			}
					

			waitForUser("inspect overlay");
			Dialog.create("Waf Waf !!");
			Dialog.addCheckbox("Check is division plane ok ?", false); 
			Dialog.show();
			isok2=Dialog.getCheckbox();
				if (isok2==false){
				isok=false;
				}
		}


	//roiManager("Deselect");
	//roiManager("Save", dir+name+"_roidivplane.zip");

	//make file with coordinates AB (big axis) 
	run("Clear Results");
	for (i=0; i<count; i++) {  
		setResult("Ax", i,Xa[i]);
		setResult("Ay", i,Ya[i]);
		setResult("Bx", i, Xb[i]);
		setResult("By", i, Yb[i]);
		updateResults();
	}
	selectWindow("Results");
	saveAs("Text", dir+name+"_axis coordinates.txt");
}




//Calculate orthogonal vector to (AB) and norm it for each frame

Vxn=newArray(n);
Vyn=newArray(n);
for (i=0; i<n; i++){
	Vx=-Yb[i]+Ya[i];
	Vy=Xb[i]-Xa[i];
	Vxn[i]=Vx/sqrt(Vx*Vx+Vy*Vy);
	Vyn[i]=Vy/sqrt(Vx*Vx+Vy*Vy);
}

//-------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------
//linescan analysis
//--------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------

if (linecheck==true){

//if image is an hyper stack, we have to extract the channel containing the jupiter, and make a z projection

	if (channels>1 || slices>1){
		waitForUser("check which channels contains your data or which Z planes to take");
		Dialog.create("Waf ");
			if (channels>1){
			nC=newArray(channels);
				for(j= 0; j<channels; j++){
				nC[j]=j+1;
				}
			Dialog.addChoice("Which channel do you want to quantify ?", nC); 
			}else{
			chanq=1;	
			}	
			if (slices>1){
				Dialog.addNumber("starting z plane",z1);
				Dialog.addNumber("ending z plane",z2);
				}
			Dialog.show();
				if (channels>1){
					chanq=Dialog.getChoice();
				}
				if (slices>1){
					z1=Dialog.getNumber;
					z2=Dialog.getNumber;
					run("Duplicate...", "title=[temp] duplicate channels="+chanq+" slices=1-"+slices+" frames=1-"+frames);
					run("Z Project...", "start="+z1+" stop="+z2+" projection=[Max Intensity] all");
					id = getImageID;
					projch="Max";
					selectWindow("temp");
					run("Z Project...", "start="+z1+" stop="+z2+" projection=[Sum Slices] all");
					idsum = getImageID;
					selectWindow("temp");
					close();
				}
		}	



//make overlay
selectImage(id);
Overlay.remove;
setLineWidth(0.1);

if (frames>1){
	
for (i=0; i<nF; i++){
	
setColor("red");
	Overlay.drawLine(Xa[i]-L*Vxn[i],Ya[i]-L*Vyn[i],Xb[i]-L*Vxn[i],Yb[i]-L*Vyn[i]);
	Overlay.drawLine(Xa[i]-L*Vxn[i],Ya[i]-L*Vyn[i],Xa[i],Ya[i]);
	Overlay.drawLine(Xb[i]-L*Vxn[i],Yb[i]-L*Vyn[i],Xb[i],Yb[i]);
	Overlay.add;
	Overlay.show;
	Overlay.setPosition(i+1);
	setColor("blue");
	Overlay.drawLine(Xa[i],Ya[i],Xb[i],Yb[i]);
	Overlay.add;
	Overlay.show;
	Overlay.setPosition(i+1);
	setColor("green");
	Overlay.drawLine(Xa[i]+L*Vxn[i],Ya[i]+L*Vyn[i],Xb[i]+L*Vxn[i],Yb[i]+L*Vyn[i]);
	Overlay.drawLine(Xa[i]+L*Vxn[i],Ya[i]+L*Vyn[i],Xa[i],Ya[i]);
	Overlay.drawLine(Xb[i]+L*Vxn[i],Yb[i]+L*Vyn[i],Xb[i],Yb[i]);
	Overlay.add;
	Overlay.show;
	Overlay.setPosition(i+1);
	}
}else{
	i=0;
	setColor("red");
	Overlay.drawLine(Xa[i]-L*Vxn[i],Ya[i]-L*Vyn[i],Xb[i]-L*Vxn[i],Yb[i]-L*Vyn[i]);
	Overlay.drawLine(Xa[i]-L*Vxn[i],Ya[i]-L*Vyn[i],Xa[i],Ya[i]);
	Overlay.drawLine(Xb[i]-L*Vxn[i],Yb[i]-L*Vyn[i],Xb[i],Yb[i]);
	Overlay.add;
	Overlay.show;
	setColor("blue");
	Overlay.drawLine(Xa[i],Ya[i],Xb[i],Yb[i]);
	Overlay.add;
	Overlay.show;
	setColor("green");
	Overlay.drawLine(Xa[i]+L*Vxn[i],Ya[i]+L*Vyn[i],Xb[i]+L*Vxn[i],Yb[i]+L*Vyn[i]);
	Overlay.drawLine(Xa[i]+L*Vxn[i],Ya[i]+L*Vyn[i],Xa[i],Ya[i]);
	Overlay.drawLine(Xb[i]+L*Vxn[i],Yb[i]+L*Vyn[i],Xb[i],Yb[i]);
	Overlay.add;
	Overlay.show;
}


selectImage(id);
saveAs("tiff", dir+n1+"_linescanoverlay"+projch+".tif");

//get where is the p2b
//if side=green, it means that the polygon1 is p2b, otherwise it's the second one
sidearray=newArray("green","red");
waitForUser("inspect overlay and check in which rectangle the p2b is");
Dialog.create("Waf ");
Dialog.addChoice(" Which side is p2b ?", sidearray); 
Dialog.show();
side=Dialog.getChoice();



//---measure linescans
newImage("plot", "32-bit Black", 2*L,nF, 1);
idplot = getImageID;
run("Clear Results");
run("Set Measurements...", "area integrated display redirect=None decimal=3");
linescan=newArray(2*L);
linescan2=newArray(2*L);
setBatchMode(true);
for (i=0; i<nF; i++){
	run("Clear Results");
	selectImage(id);
	setSlice(i+1);
		for (j=0; j<2*L; j++){
			k=-L+j;
			selectImage(id);
			//modif if the p2b is anterior or not
			if (side=="green"){
			makeLine(Xa[i]-k*Vxn[i], Ya[i]-k*Vyn[i], Xb[i]-k*Vxn[i], Yb[i]-k*Vyn[i],1);	
			}else{
			makeLine(Xa[i]+k*Vxn[i], Ya[i]+k*Vyn[i], Xb[i]+k*Vxn[i], Yb[i]+k*Vyn[i],1);
			}
			run("Measure");
			linescan[j]=getResult("RawIntDen",j);
			selectWindow("plot");
			setPixel(j, i, getResult("RawIntDen",j));
			linescan2[j]=k;		
		}	
}

selectImage(idplot);
resetMinAndMax();
//saveAs("tiff", dir+"linescankymo"+projch+".tif");		

//--------------------------------------------------------------------------
// find maximas
//--------------------------------------------------------------------------
//background can be taken on the pixels on both side of the linescan the back2 values are values average on p pixels
//peak can be averaged on pp pixels

x1=newArray(nF);
x1val=newArray(nF);
x1valav=newArray(nF);
x1back=newArray(nF);
x1back2=newArray(nF);
x2=newArray(nF);
x2val=newArray(nF);
x2valav=newArray(nF);
x2back=newArray(nF);

x2back2=newArray(nF);

setBatchMode(true);
for (i=0; i<nF; i++){
noise=0;
npeaks=2;
selectImage(idplot);
makeRectangle(0, i, L, 1);
run("Duplicate...", "title=zoom.tif");
idzoom= getImageID;
while (npeaks!=1){
noise=noise+1000;
run("Find Maxima...", "noise="+noise+" output=List");
npeaks=nResults;
}
selectImage(idzoom);
close();
x1[i]=getResult("X",0);
selectImage(idplot);
x1val[i]=getPixel(x1[i], i);
x1valav[i]=0;
for (r=0; r<2*pp+1; r++){
	pos=x1[i]-pp+r;
	x1valav[i]=x1valav[i]+getPixel(pos, i);
}
x1valav[i]=x1valav[i]/(2*pp+1);

x1back[i]=getPixel(0, i);
x1back2[i]=0;
for (r=0; r<p; r++){
x1back2[i]=x1back2[i]+getPixel(r, i);

}
x1back2[i]=x1back2[i]/(p);


noise=0;
npeaks=2;
selectImage(idplot);
makeRectangle(L, i, 2*L, 1);
run("Duplicate...", "title=zoom.tif");
idzoom= getImageID;
while (npeaks!=1){
noise=noise+1000;
run("Find Maxima...", "noise="+noise+" output=List");
npeaks=nResults;
}
selectImage(idzoom);
close();
x2[i]=getResult("X",0);
selectImage(idplot);
x2val[i]=getPixel(x2[i]+L, i);
x2valav[i]=0;
for (r=0; r<2*pp+1; r++){
	pos=x2[i]-pp+r+L;
	x2valav[i]=x2valav[i]+getPixel(pos, i);
}
x2valav[i]=x2valav[i]/(2*pp+1);

x2back[i]=getPixel(2*L-1, i);
x2back2[i]=0;
for (r=0; r<p; r++){
x2back2[i]=x2back2[i]+getPixel(2*L-1-r, i);
}
x2back2[i]=x2back2[i]/(p);
}

selectImage(idplot);
Overlay.remove;
setLineWidth(1);

if (frames==1){
	setColor("green");
	Overlay.drawRect(x1[0],0, 1, 1);
	Overlay.add;
	Overlay.show;
	setColor("red");
	Overlay.drawRect(L+x2[0],0, 1, 1);
	Overlay.add;
	Overlay.show;
}else{
	for (i=0; i<nF-1; i++){
	setColor("green");
	Overlay.drawLine(x1[i],i,x1[i+1],i+1);
	Overlay.add;
	Overlay.show;
	setColor("red");
	Overlay.drawLine(L+x2[i],i,L+x2[i+1],i+1);
	Overlay.add;
	Overlay.show;
	}
}

//saveAs("tiff", dir+"linescanpeakdetection"+projch+".tif");	
saveAs("tiff", dir+name+"linescan"+projch+".tif");




//--------------------------------------------------------------------------
// make movie of the linescans
//--------------------------------------------------------------------------
setBatchMode(false);
setLineWidth(1);
	if (linemovie==true){
		for (i=0; i<nF; i++){
		selectImage(idplot);
		makeLine(0,i, 2*L,i);		
		run("Plot Profile");
		}
	selectImage(idplot);
	close();

	if (frames==1){
	saveAs("tiff", dir+name+"linescan"+projch+".tif");	
	}else{
	run("Images to Stack", "name=Stack title=[] use");
	saveAs("tiff", dir+name+"linescanmovie"+projch+".tif");	
	}
}



//-------------------------------------------------------------------------------------------------
//redo everything in SUM projection//
if (slices>1){
selectImage(idsum);
projch="Sum";
Overlay.remove;
setLineWidth(0.1);

if (frames>1){
	for (i=0; i<nF; i++){
		setColor("red");
		Overlay.drawLine(Xa[i]-L*Vxn[i],Ya[i]-L*Vyn[i],Xb[i]-L*Vxn[i],Yb[i]-L*Vyn[i]);
		Overlay.drawLine(Xa[i]-L*Vxn[i],Ya[i]-L*Vyn[i],Xa[i],Ya[i]);
		Overlay.drawLine(Xb[i]-L*Vxn[i],Yb[i]-L*Vyn[i],Xb[i],Yb[i]);
		Overlay.add;
		Overlay.show;
		Overlay.setPosition(i+1);
		setColor("blue");
		Overlay.drawLine(Xa[i],Ya[i],Xb[i],Yb[i]);
		Overlay.add;
		Overlay.show;
		Overlay.setPosition(i+1);
		setColor("green");
		Overlay.drawLine(Xa[i]+L*Vxn[i],Ya[i]+L*Vyn[i],Xb[i]+L*Vxn[i],Yb[i]+L*Vyn[i]);
		Overlay.drawLine(Xa[i]+L*Vxn[i],Ya[i]+L*Vyn[i],Xa[i],Ya[i]);
		Overlay.drawLine(Xb[i]+L*Vxn[i],Yb[i]+L*Vyn[i],Xb[i],Yb[i]);
		Overlay.add;
		Overlay.show;
		Overlay.setPosition(i+1);
	}
}else{
	i=0;
	setColor("red");
	Overlay.drawLine(Xa[i]-L*Vxn[i],Ya[i]-L*Vyn[i],Xb[i]-L*Vxn[i],Yb[i]-L*Vyn[i]);
	Overlay.drawLine(Xa[i]-L*Vxn[i],Ya[i]-L*Vyn[i],Xa[i],Ya[i]);
	Overlay.drawLine(Xb[i]-L*Vxn[i],Yb[i]-L*Vyn[i],Xb[i],Yb[i]);
	Overlay.add;
	Overlay.show;
	setColor("blue");
	Overlay.drawLine(Xa[i],Ya[i],Xb[i],Yb[i]);
	Overlay.add;
	Overlay.show;
	setColor("green");
	Overlay.drawLine(Xa[i]+L*Vxn[i],Ya[i]+L*Vyn[i],Xb[i]+L*Vxn[i],Yb[i]+L*Vyn[i]);
	Overlay.drawLine(Xa[i]+L*Vxn[i],Ya[i]+L*Vyn[i],Xa[i],Ya[i]);
	Overlay.drawLine(Xb[i]+L*Vxn[i],Yb[i]+L*Vyn[i],Xb[i],Yb[i]);
	Overlay.add;
	Overlay.show;
}

//saveAs("tiff", dir+n1+"_linescanoverlay"+projch+".tif");

//---measure linescans
newImage("plot2", "32-bit Black", 2*L,nF, 1);
idplot2 = getImageID;
run("Clear Results");
run("Set Measurements...", "area integrated display redirect=None decimal=3");
linescan=newArray(2*L);
linescan2=newArray(2*L);
setBatchMode(true);
setLineWidth(1);
for (i=0; i<nF; i++){
	run("Clear Results");
	selectImage(idsum);
	setSlice(i+1);
		for (j=0; j<2*L; j++){
			k=-L+j;
			selectImage(idsum);
			//modif if the p2b is anterior or not
			if (side=="green"){
			makeLine(Xa[i]-k*Vxn[i], Ya[i]-k*Vyn[i], Xb[i]-k*Vxn[i], Yb[i]-k*Vyn[i]);	
			}else{
			makeLine(Xa[i]+k*Vxn[i], Ya[i]+k*Vyn[i], Xb[i]+k*Vxn[i], Yb[i]+k*Vyn[i]);
			}
			run("Measure");
			linescan[j]=getResult("RawIntDen",j);
			selectWindow("plot2");
			setPixel(j, i, getResult("RawIntDen",j));
			linescan2[j]=k;		
		}	
}

selectImage(idplot2);
resetMinAndMax();

//saveAs("tiff", dir+"linescankymo"+projch+".tif");		

//--------------------------------------------------------------------------
// find maximas
//--------------------------------------------------------------------------
//background can be taken on the pixels on both side of the linescan the back2 values are values average on p pixels
//peak can be averaged on pp pixels

sx1=newArray(nF);
sx1val=newArray(nF);
sx1valav=newArray(nF);
sx1back=newArray(nF);
sx1back2=newArray(nF);
sx2=newArray(nF);
sx2val=newArray(nF);
sx2valav=newArray(nF);
sx2back=newArray(nF);
sx2back2=newArray(nF);

setBatchMode(true);
for (i=0; i<nF; i++){
noise=0;
npeaks=2;
selectImage(idplot2);
makeRectangle(0, i, L, 1);
run("Duplicate...", "title=zoom.tif");
idzoom= getImageID;
while (npeaks!=1){
noise=noise+1000;
run("Find Maxima...", "noise="+noise+" output=List");
npeaks=nResults;
}
selectImage(idzoom);
close();
sx1[i]=getResult("X",0);
selectImage(idplot2);
sx1val[i]=getPixel(sx1[i], i);
sx1valav[i]=0;
for (r=0; r<2*pp+1; r++){
	pos=x1[i]-pp+r;
	sx1valav[i]=sx1valav[i]+getPixel(pos, i);
}
sx1valav[i]=sx1valav[i]/(2*pp+1);

sx1back[i]=getPixel(0, i);
sx1back2[i]=0;
for (r=0; r<p; r++){
sx1back2[i]=sx1back2[i]+getPixel(r, i);
}
sx1back2[i]=sx1back2[i]/(p);


noise=0;
npeaks=2;
selectImage(idplot2);
makeRectangle(L, i, 2*L, 1);
run("Duplicate...", "title=zoom.tif");
idzoom= getImageID;
while (npeaks!=1){
noise=noise+1000;
run("Find Maxima...", "noise="+noise+" output=List");
npeaks=nResults;
}
selectImage(idzoom);
close();
sx2[i]=getResult("X",0);
selectImage(idplot2);
sx2val[i]=getPixel(sx2[i]+L, i);
sx2valav[i]=0;
for (r=0; r<2*pp+1; r++){
	pos=x2[i]-pp+r+L;
	sx2valav[i]=sx2valav[i]+getPixel(pos, i);
}
sx2valav[i]=sx2valav[i]/(2*pp+1);

sx2back[i]=getPixel(2*L-1, i);
sx2back2[i]=0;
for (r=0; r<p; r++){
sx2back2[i]=sx2back2[i]+getPixel(2*L-1-r, i);
}
sx2back2[i]=sx2back2[i]/(p);
}

selectImage(idplot2);
Overlay.remove;


if (frames==1){
	setColor("green");
	Overlay.drawRect(x1[0],0, 1, 1);
	Overlay.add;
	Overlay.show;
	setColor("red");
	Overlay.drawRect(L+x2[0],0, 1, 1);
	Overlay.add;
	Overlay.show;
}else{
	for (i=0; i<nF-1; i++){
	setColor("green");
	Overlay.drawLine(x1[i],i,x1[i+1],i+1);
	Overlay.add;
	Overlay.show;
	setColor("red");
	Overlay.drawLine(L+x2[i],i,L+x2[i+1],i+1);
	Overlay.add;
	Overlay.show;
	}
}

//saveAs("tiff", dir+"linescanpeakdetection"+projch+".tif");	
saveAs("tiff", dir+name+"linescan"+projch+".tif");


//--------------------------------------------------------------------------
// make movie of the linescans
//--------------------------------------------------------------------------
setBatchMode(false);
setLineWidth(1);
	if (linemovie==true){
		for (i=0; i<nF; i++){
		selectImage(idplot2);
		makeLine(0,i, 2*L,i);		
		run("Plot Profile");
		}
	selectImage(idplot2);
	close();

	if (frames==1){
	saveAs("tiff", dir+name+"linescan"+projch+".tif");	
	}else{
	run("Images to Stack", "name=Stack title=[] use");
	saveAs("tiff", dir+name+"linescanmovie"+projch+".tif");	
	}
	}
}
}

if (constriction==true){
//---------------------------------------------------
//--measure of the global signal width constriction over time (ex to measure a Pav like signal constriction when you only have jupiter
//---------------------------------------------------


	newImage("kymowidth", "32-bit Black",wd,nF, 1);
	idwidth = getImageID;
	setBatchMode(true) ;
		for (i=0; i<nF; i++) {
		//get center
		Ox=(Xa[i]+Xb[i])/2;
		Oy=(Ya[i]+Yb[i])/2;
		//make colinear vector to AB
		Vy2=Yb[i]-Ya[i];
		Vx2=Xb[i]-Xa[i];
		Vxn2=Vx2/sqrt(Vx2*Vx2+Vy2*Vy2);
		Vyn2=Vy2/sqrt(Vx2*Vx2+Vy2*Vy2);

		selectImage(id);//id is the Max proj if more than one slice 
		setSlice(i+1);
		makeLine(Ox+wd*Vxn2/2,Oy+wd*Vyn2/2,Ox-wd*Vxn2/2,Oy-wd*Vyn2/2,wd2);
		profile = getProfile();
			for (j=0; j<profile.length; j++){
			selectImage(idwidth);
      			setPixel(j, i, profile[j]);
  			}
		}
		
		//measure "kymograph"
		selectImage(idwidth);
		resetMinAndMax();
		run("16-bit");
		hk=getHeight;
		wk=getWidth;
		D=newArray(hk);
		Dx=newArray(hk);
		X12=newArray(hk);
		X22=newArray(hk);
		V=newArray(wk);
		M=newArray(wk);

		// parameters initiation
		ok=false;
		k=500;
		fix=getHeight;
		run("Set Measurements...", "  integrated display redirect=None decimal=3");
		while (ok==false) {
			setBatchMode(true);
  		    	for (j=0; j<hk; j++){
			showProgress(j/hk);
			Dx[j]=j+1;
			run("Clear Results");
			selectImage(idwidth);
			makeRectangle(0, j, wk, 1);
			profile = getProfile();
			run("Duplicate...", "title=findmax");
			idfindMax = getImageID;
			p="noise="+k+" output=[List]";
			run("Find Maxima...", p);
			M=newArray(nResults);
				for (i=0; i<nResults; i++){
				M[i]=getResult("X", i);
				}	
			selectImage(idfindMax);
			close();		

	// finds the coordinates of first maxima on the left and the first from the right and their respective values x1 and x2
	Array.getStatistics(M, min, max, mean, stdDev);
	m1=min;
	m2=max;
	selectImage(idwidth);
	V1=getPixel(m1,j);
	V2=getPixel(m2,j);
	
	// calculates the two thresholds (t1 on the left t2 on the right)
	Array.getStatistics(profile, min, max, mean, stdDev);
	t1=(V1-min)/2+min;
	t2=(V2-min)/2+min;
	// finds the coordinates of the 2 maximas
	x12=0;
	x22=wk-1;
	while (profile[x12]<t1) {
      	x12=x12+1;
   	}
	while (profile[x22]<t2) {
      	x22=x22-1;
   	}
   	
	// linear interpolation for x1 and x2
		if (x12!=0){
		dx=(t1-profile[x12-1])/(profile[x12]-profile[x12-1]);
		x12=x12-1+dx;
		}
		if (x22!=wk-1){	
		dx=(t2-profile[x22+1])/(profile[x22]-profile[x22+1]);
		x22=x22+1-dx;
		}

		if(j<fix) {
		D[j]=x22-x12;
		X12[j]=x12;
		X22[j]=x22;
		}else{
		D[j]=D[fix];
		X12[j]=X12[fix];
		X22[j]=X22[fix];
		}
	}
setBatchMode("exit and display");
Plot.create("size of pavaroti over big axis", "time (frame)", "Size Pav (pixel)", Dx, D);
Plot.setLimits(0, hk, 0, wk);
Plot.show();
selectImage(idwidth);
setLineWidth(0.1);
Overlay.remove;
	for (j=0; j<hk-1; j++){
	setColor("green");
	Overlay.drawLine(X12[j],j,X12[j+1],j+1);
	Overlay.add;
	Overlay.show;
	setColor("red");
	Overlay.drawLine(X22[j],j,X22[j+1],j+1);
	Overlay.add;
	Overlay.show;
	}
waitForUser("inspect overlay");
Dialog.create("Waf Waf !!");
Dialog.addCheckbox("Check is contraction ok ?", false); 
Dialog.addNumber("If not which threshold for peak detection to try ?",k );
Dialog.addNumber("If not after which frame to fix ?",fix );
Dialog.show();
ok = Dialog.getCheckbox();
k=Dialog.getNumber();
fix=Dialog.getNumber();
selectWindow("size of pavaroti over big axis");
close();
}
// save overlay and make result file
selectImage(idwidth);
saveAs("Tiff", dir+name+"_contractionoverlay.tiff");

}	



if (regioncheck==true){

//-------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------
//REGION integration analysis
//--------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------

//prepare the polygons a1 and a2 are symetrical relative to a, same thing for b1,b2,b.
// the value l gives the lengh of the spindle along its short axis
//potential change of the polygon from rectangle to pyramid if minimal size option checked (value d)


isok=false;
while (isok==false){

Xa1=newArray(n);
Ya1=newArray(n);
Xb1=newArray(n);
Yb1=newArray(n);
Xa2=newArray(n);
Ya2=newArray(n);
Xb2=newArray(n);
Yb2=newArray(n);


if (minsize==false){
	for (i=0; i<n; i++){
		Xa1[i]=Xa[i]+l*Vxn[i];
		Ya1[i]=Ya[i]+l*Vyn[i];
		Xb1[i]=Xb[i]+l*Vxn[i];
		Yb1[i]=Yb[i]+l*Vyn[i];
		Xa2[i]=Xa[i]-l*Vxn[i];
		Ya2[i]=Ya[i]-l*Vyn[i];
		Xb2[i]=Xb[i]-l*Vxn[i];
		Yb2[i]=Yb[i]-l*Vyn[i];
	}
}else{
	for (i=0; i<n; i++){
		AB=sqrt((Xa[i]-Xb[i])*(Xa[i]-Xb[i])+(Ya[i]-Yb[i])*(Ya[i]-Yb[i]));
			if (AB>2*d){
				Xa1[i]=Xa[i]+l*Vxn[i];
				Ya1[i]=Ya[i]+l*Vyn[i];
				Xb1[i]=Xb[i]+l*Vxn[i];
				Yb1[i]=Yb[i]+l*Vyn[i];
				Xa2[i]=Xa[i]-l*Vxn[i];
				Ya2[i]=Ya[i]-l*Vyn[i];
				Xb2[i]=Xb[i]-l*Vxn[i];
				Yb2[i]=Yb[i]-l*Vyn[i];
			}else{
				Ox=1/2*(Xa[i]+Xb[i]);
				Oy=1/2*(Ya[i]+Yb[i]);
				OA=sqrt((Xa[i]-Ox)*(Xa[i]-Ox)+(Ya[i]-Oy)*(Ya[i]-Oy));
				OB=sqrt((Xb[i]-Ox)*(Xb[i]-Ox)+(Yb[i]-Oy)*(Yb[i]-Oy));
				Xa1[i]=Ox+d/OA*(Xa[i]-Ox)+l*Vxn[i];
				Ya1[i]=Oy+d/OA*(Ya[i]-Oy)+l*Vyn[i];
				Xb1[i]=Ox+d/OA*(Xb[i]-Ox)+l*Vxn[i];
				Yb1[i]=Oy+d/OA*(Yb[i]-Oy)+l*Vyn[i];
				Xa2[i]=Ox+d/OA*(Xa[i]-Ox)-l*Vxn[i];
				Ya2[i]=Oy+d/OA*(Ya[i]-Oy)-l*Vyn[i];
				Xb2[i]=Ox+d/OA*(Xb[i]-Ox)-l*Vxn[i];
				Yb2[i]=Oy+d/OA*(Yb[i]-Oy)-l*Vyn[i];
			}
	}
}

//make the overlay 
selectImage(idori);
Overlay.remove;
setLineWidth(0.1);
pos=1;
	for (i=0; i<frames; i++){
		for (j=1; j<channels*slices+1; j++){		
				setColor("green");
				Overlay.drawLine(Xa[i],Ya[i],Xb[i],Yb[i]);
				Overlay.drawLine(Xb[i],Yb[i],Xb1[i],Yb1[i]);
				Overlay.drawLine(Xb1[i],Yb1[i],Xa1[i],Ya1[i]);
				Overlay.drawLine(Xa1[i],Ya1[i],Xa[i],Ya[i]);
				Overlay.add;
				Overlay.show;
				Overlay.setPosition(pos);			
				setColor("red");
				Overlay.drawLine(Xa[i],Ya[i],Xb[i],Yb[i]);
				Overlay.drawLine(Xb[i],Yb[i],Xb2[i],Yb2[i]);
				Overlay.drawLine(Xb2[i],Yb2[i],Xa2[i],Ya2[i]);
				Overlay.drawLine(Xa2[i],Ya2[i],Xa[i],Ya[i]);
				Overlay.add;
				Overlay.show;
				Overlay.setPosition(pos);
				setColor("blue");
				Overlay.drawLine(Xa[i],Ya[i],Xb[i],Yb[i]);
				Overlay.add;
				Overlay.show;
				Overlay.setPosition(pos);
				pos=pos+1;
			}
		}

waitForUser("inspect overlay for REGION analysis");
Dialog.create("Are you happy ?");
Dialog.addCheckbox(" Yes it's fine go on ?", false); 
Dialog.addNumber("If not which length over the small axis of the spindle do you want ?",l );
Dialog.addCheckbox("Do you want to constrain the length over the bis axis of the spindle ?",minsize);
Dialog.addNumber("Which length over the big axis of the spindle do you want ?",d );
Dialog.addCheckbox("do you want to make locally correct the background ?",regionback);
Dialog.show();
isok = Dialog.getCheckbox();
l=Dialog.getNumber();
minsize= Dialog.getCheckbox();
d =Dialog.getNumber();
regionback= Dialog.getCheckbox();
}




//get where is the p2b unless you did the linescan before
	if (linecheck==false){
	sidearray=newArray("green","red");
	}

if (Stack.isHyperstack==1){
	Stack.getDimensions(width, height, channels, slices, frames);
	nC=newArray(channels);
		for(j= 0; j<channels; j++){
			nC[j]=j+1;
		}
	Dialog.create("Waf ");
	if (linecheck==false){
	Dialog.addChoice(" Which side is p2b ?", sidearray); 
	}
	Dialog.addChoice("Which channel do you want to quantify ?", nC); 
	if (slices>1){
	Dialog.addNumber("starting z plane",z1);
	Dialog.addNumber("ending z plane",z2);
	}
	Dialog.show();
	if (linecheck==false){
	side=Dialog.getChoice();
	}
	chanq=Dialog.getChoice();
	if (slices>1){
	z1=Dialog.getNumber;
	z2=Dialog.getNumber;
	}

}else{
	if (linecheck==false){
	Dialog.create("Waf ");
	Dialog.addChoice(" Which side is p2b ?", sidearray); 
	Dialog.show();
	side=Dialog.getChoice();
	}
}

//draw the region for background correction background will be taken locally on each z plane for each timepoint

if (regionback==true){
	roiManager("reset");
	isok=false;
		while (isok==false){
				waitForUser("draw your background ROI in each timeframe");
					count=roiManager("count");
					n=frames;
					if (count!=frames){
						showMessage("you did not draw on every timeframe");	
						isok=false;
					}else{
						isok=true;
					}
			}	

	roiManager("Deselect");
	roiManager("Save", dir+name+"_regionbackground.zip");
}

//measure the data
run("Clear Results");
run("Set Measurements...", "area integrated display redirect=None decimal=3");
setLineWidth(1);
Intensity1=newArray(n);
Intensity2=newArray(n);
Intensity1back=newArray(n);
Intensity2back=newArray(n);

label=newArray(n);
chan=newArray(n);
selectImage(idori);

if (Stack.isHyperstack==1){
		if (slices>1){
			for (i=0; i<frames; i++){
			j=i+1;
			chan[i]=chanq;
			Intensity1[i]=0;
			Intensity2[i]=0;
			Intensity1back[i]=0;
			Intensity2back[i]=0;
			for (y=z1; y<z2+1; y++){
				run("Clear Results");
				setLineWidth(1);
				Stack.setPosition(chanq, y, j);
				makePolygon(Xa[i],Ya[i],Xb[i],Yb[i],Xb1[i],Yb1[i],Xa1[i],Ya1[i]);
				run("Measure");
				makePolygon(Xa[i],Ya[i],Xb[i],Yb[i],Xb2[i],Yb2[i],Xa2[i],Ya2[i]);
				run("Measure");
			        Intensity1[i]=Intensity1[i]+getResult("RawIntDen",0);
				Intensity2[i]=Intensity2[i]+getResult("RawIntDen",1);
					if (regionback==true){
					roiManager("select", i);
					run("Measure");
					Intensity1back[i]=Intensity1back[i]+getResult("RawIntDen",0)-getResult("RawIntDen",2)*getResult("Area",0)/getResult("Area",2);
					Intensity2back[i]=Intensity2back[i]+getResult("RawIntDen",1)-getResult("RawIntDen",2)*getResult("Area",1)/getResult("Area",2);			
					}						
				}
			label[i]=getResultLabel(0);
		}	

		}else{
			for (i=0; i<frames; i++){
			j=i+1;
			Stack.setPosition(chanq, 1, j);
			run("Clear Results");
			makePolygon(Xa[i],Ya[i],Xb[i],Yb[i],Xb1[i],Yb1[i],Xa1[i],Ya1[i]);
			run("Measure");
			makePolygon(Xa[i],Ya[i],Xb[i],Yb[i],Xb2[i],Yb2[i],Xa2[i],Ya2[i]);
			run("Measure");
			Intensity1[i]=getResult("RawIntDen",0);
			Intensity2[i]=getResult("RawIntDen",1);	
					if (regionback==true){
					roiManager("select", i);
					run("Measure");
					Intensity1back[i]=getResult("RawIntDen",0)-getResult("RawIntDen",2)*getResult("Area",0)/getResult("Area",2);
					Intensity2back[i]=getResult("RawIntDen",1)-getResult("RawIntDen",2)*getResult("Area",1)/getResult("Area",2);			
					}		
			label[i]=getResultLabel(0);
			chan[i]=chanq;
			}
		}
}else{
	for (i=0; i<n; i++){
	j=i+1;
	setSlice(i+1);
	run("Clear Results");
	makePolygon(Xa[i],Ya[i],Xb[i],Yb[i],Xb1[i],Yb1[i],Xa1[i],Ya1[i]);
	run("Measure");
	makePolygon(Xa[i],Ya[i],Xb[i],Yb[i],Xb2[i],Yb2[i],Xa2[i],Ya2[i]);
	run("Measure");
	Intensity1[i]=getResult("RawIntDen",0);
	Intensity2[i]=getResult("RawIntDen",1);
		if (regionback==true){
			roiManager("select", i);
			run("Measure");
			Intensity1back[i]=getResult("RawIntDen",0)-getResult("RawIntDen",2)*getResult("Area",0)/getResult("Area",2);
			Intensity2back[i]=getResult("RawIntDen",1)-getResult("RawIntDen",2)*getResult("Area",1)/getResult("Area",2);			
		}
	label[i]=getResultLabel(0);
	chan[i]=1;
	}
}
selectImage(idori);
saveAs("Tiff", dir+name+"_regionoverlay.tiff");
}

//--------------make Results file-------------------
run("Clear Results");
setResult("Label", 0,name);
setResult("Channel quant", 0,chanq);
setResult("Timepoint", 0,0);
if (slices>1){
	setResult("z1", 0,z1);
	setResult("z2", 0,z2);
}
if (linecheck==true){
	if (slices==1){	
	setResult("Linescan", 0,0);
	//all these next lines are useless, but there only to initiate the collumns
	i=0;
	setResult("p2b peak coordinate ", i,x1[i]);
	setResult("p2b peak value ", i,x1val[i]);
	setResult("p2b peak value averaged on "+2*pp+1+" pixels ", i,x1valav[i]);
	setResult("p2b peak background ", i,x1back[i]);
	setResult("p2b peak background averaged on "+p+" pixels", i,x1back2[i]);
	setResult("p2a peak coordinate ", i,x2[i]+L);
	setResult("p2a peak value ", i,x2val[i]);
	setResult("p2a peak value averaged on "+2*pp+1+" pixels ", i,x2valav[i]);
	setResult("p2a peak background ", i,x2back[i]);
	setResult("p2a peak background averaged on "+p+" pixels", i,x2back2[i]);
	setResult("p2b/p2a ratio", i,(x1val[i]-x2val[i])/(x2val[i])*100);
	setResult("p2b/p2a ratio back corrected", i,((x1valav[i]-x1back2[i])-(x2valav[i]-x2back2[i]))/(x2valav[i]-x2back2[i])*100);
	}else{
	setResult("Linescan", 0,0);
	i=0;
	setResult("MAX p2b peak coordinate ", i,x1[i]);
	setResult("MAX p2b peak value ", i,x1val[i]);
	setResult("MAX p2b peak value averaged on "+2*pp+1+" pixels ", i,x1valav[i]);
	setResult("MAX p2b peak background ", i,x1back[i]);
	setResult("MAX p2b peak background averaged on "+p+" pixels", i,x1back2[i]);
	setResult("MAX p2a peak coordinate ", i,x2[i]+L);
	setResult("MAX p2a peak value ", i,x2val[i]);
	setResult("MAX p2a peak value averaged on "+2*pp+1+" pixels ", i,x2valav[i]);
	setResult("MAX p2a peak background ", i,x2back[i]);
	setResult("MAX p2a peak background averaged on "+p+" pixels", i,x2back2[i]);
	setResult("MAX p2b/p2a ratio", i,(x1val[i]-x2val[i])/(x2val[i])*100);
	setResult("MAX p2b/p2a ratio back corrected", i,((x1valav[i]-x1back2[i])-(x2valav[i]-x2back2[i]))/(x2valav[i]-x2back2[i])*100);
	setResult("SUM p2b peak coordinate ", i,sx1[i]);
	setResult("SUM p2b peak value ", i,sx1val[i]);
	setResult("SUM p2b peak value averaged on "+2*pp+1+" pixels ", i,sx1valav[i]);
	setResult("SUM p2b peak background ", i,sx1back[i]);
	setResult("SUM p2b peak background averaged on "+p+" pixels", i,sx1back2[i]);
	setResult("SUM p2a peak coordinate ", i,sx2[i]+L);
	setResult("SUM p2a peak value ", i,sx2val[i]);
	setResult("SUM p2a peak value averaged on "+2*pp+1+" pixels ", i,sx2valav[i]);
	setResult("SUM p2a peak background ", i,sx2back[i]);
	setResult("SUM p2a peak background averaged on "+p+" pixels", i,sx2back2[i]);
	setResult("SUM p2b/p2a ratio", i,(sx1val[i]-sx2val[i])/(sx2val[i])*100);
	setResult("SUM p2b/p2a ratio back corrected", i,((sx1valav[i]-sx1back2[i])-(sx2valav[i]-sx2back2[i]))/(sx2valav[i]-sx2back2[i])*100);
	}
}	
	if (constriction==true){
	setResult("spindle Width in px", 0,0);	
	}

if (regioncheck==true){
	setResult("Z integration", 0,0);
}
updateResults();


for (i=0; i<nF; i++) {
	setResult("Timepoint", i,i+1);
	//linescan
	if (linecheck==true){
		if (slices==1){	
		setResult("p2b peak coordinate ", i,x1[i]);
	setResult("p2b peak value ", i,x1val[i]);
	setResult("p2b peak value averaged on "+2*pp+1+" pixels ", i,x1valav[i]);
	setResult("p2b peak background ", i,x1back[i]);
	setResult("p2b peak background averaged on "+p+" pixels", i,x1back2[i]);
	setResult("p2a peak coordinate ", i,x2[i]+L);
	setResult("p2a peak value ", i,x2val[i]);
	setResult("p2a peak value averaged on "+2*pp+1+" pixels ", i,x2valav[i]);
	setResult("p2a peak background ", i,x2back[i]);
	setResult("p2a peak background averaged on "+p+" pixels", i,x2back2[i]);
	setResult("p2b/p2a ratio", i,(x1val[i]-x2val[i])/(x2val[i])*100);
	setResult("p2b/p2a ratio back corrected", i,((x1valav[i]-x1back2[i])-(x2valav[i]-x2back2[i]))/(x2valav[i]-x2back2[i])*100);			
		
		}else{
	setResult("MAX p2b peak coordinate ", i,x1[i]);
	setResult("MAX p2b peak value ", i,x1val[i]);
	setResult("MAX p2b peak value averaged on "+2*pp+1+" pixels ", i,x1valav[i]);
	setResult("MAX p2b peak background ", i,x1back[i]);
	setResult("MAX p2b peak background averaged on "+p+" pixels", i,x1back2[i]);
	setResult("MAX p2a peak coordinate ", i,x2[i]+L);
	setResult("MAX p2a peak value ", i,x2val[i]);
	setResult("MAX p2a peak value averaged on "+2*pp+1+" pixels ", i,x2valav[i]);
	setResult("MAX p2a peak background ", i,x2back[i]);
	setResult("MAX p2a peak background averaged on "+p+" pixels", i,x2back2[i]);
	setResult("MAX p2b/p2a ratio", i,(x1val[i]-x2val[i])/(x2val[i])*100);
	setResult("MAX p2b/p2a ratio back corrected", i,((x1valav[i]-x1back2[i])-(x2valav[i]-x2back2[i]))/(x2valav[i]-x2back2[i])*100);
	setResult("SUM p2b peak coordinate ", i,sx1[i]);
	setResult("SUM p2b peak value ", i,sx1val[i]);
	setResult("SUM p2b peak value averaged on "+2*pp+1+" pixels ", i,sx1valav[i]);
	setResult("SUM p2b peak background ", i,sx1back[i]);
	setResult("SUM p2b peak background averaged on "+p+" pixels", i,sx1back2[i]);
	setResult("SUM p2a peak coordinate ", i,sx2[i]+L);
	setResult("SUM p2a peak value ", i,sx2val[i]);
	setResult("SUM p2a peak value averaged on "+2*pp+1+" pixels ", i,sx2valav[i]);
	setResult("SUM p2a peak background ", i,sx2back[i]);
	setResult("SUM p2a peak background averaged on "+p+" pixels", i,sx2back2[i]);
	setResult("SUM p2b/p2a ratio", i,(sx1val[i]-sx2val[i])/(sx2val[i])*100);
	setResult("SUM p2b/p2a ratio back corrected", i,((sx1valav[i]-sx1back2[i])-(sx2valav[i]-sx2back2[i]))/(sx2valav[i]-sx2back2[i])*100);		
		}
	}
		if (constriction==true){
		setResult("spindle Width in px", i,D[i]);	
		}
	
	//region
	if (regioncheck==true){
		if (side=="green"){
		setResult("Intensity p2a", i,Intensity2[i]);
		setResult("Intensity p2b", i,Intensity1[i]);
		setResult("ratio (p2b-p2a/p2a)* 100 ", i,  (Intensity1[i]-Intensity2[i])/Intensity2[i]*100);
			if (regionback==true){
			setResult("Intensity p2a back corrected", i,Intensity2back[i]);
			setResult("Intensity p2b back corrected", i,Intensity1back[i]);
			setResult("ratio (p2b-p2a/p2a)* 100 back corrected", i,  (Intensity1back[i]-Intensity2back[i])/Intensity2back[i]*100);	
			}
		}else{
		setResult("Intensity p2a", i,Intensity1[i]);
		setResult("Intensity p2b", i,Intensity2[i]);
		setResult("ratio (p2b-p2a/p2a)* 100 ", i,  (Intensity2[i]-Intensity1[i])/Intensity1[i]*100);
			if (regionback==true){
			setResult("Intensity p2a back corrected", i,Intensity1back[i]);
			setResult("Intensity p2b back corrected", i,Intensity2back[i]);
			setResult("ratio (p2b-p2a/p2a)* 100 back corrected", i,  (Intensity2back[i]-Intensity1back[i])/Intensity1back[i]*100);	
			}
	}
	updateResults();
}
selectWindow("Results");
saveAs("Text", dir+name+"_results_linescan.xls");
}

}
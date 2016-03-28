#include "ofMain.h"

#include "ofxDisplayLayout.h"

class ofApp : public ofBaseApp
{
	
	ofxDisplayLayout manager;
	
public:
	
	void setup() {
		ofSetLogLevel(OF_LOG_VERBOSE);
	}
	
	void draw() {
		
		stringstream report;
		report << "Press [s] to save current display order" << endl;
		report << "Press [l] to load settings, align displays" << endl;
		ofDrawBitmapString(report.str(), 20, 20);
		
		manager.debugDraw(300, 300);
	}
	
	void keyPressed(int key) {
    
		// use ofxDisplayLayout::ALIGN_HORIZONTAL or ofxDisplayLayout::ALIGN_VERTICAL
    
		if (key == 's') {
			if (!manager.save("display.txt", ofxDisplayLayout::ALIGN_HORIZONTAL)) {
				ofSystemAlertDialog("save failed.");
			};
		}
		if (key == 'l') {
			if (!manager.load("display.txt", ofxDisplayLayout::ALIGN_HORIZONTAL)) {
				ofSystemAlertDialog("load failed.");
			};
		}
	}
};



#pragma mark -
#pragma mark main
int main(){
	ofSetupOpenGL(1024, 780, OF_WINDOW);
	ofRunApp(new ofApp());
}

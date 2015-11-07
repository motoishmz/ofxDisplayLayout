#include "ofMain.h"

#include "ofxDisplayLayout.h"

class ofApp : public ofBaseApp
{
	
	ofxDisplayLayout manager;
	
public:
	
	void setup() {
		ofSetLogLevel(OF_LOG_VERBOSE);
	}
	
	void update() {
		
	}
	
	void draw() {
		
		stringstream report;
		report << "Press [s] to save current display order" << endl;
		report << "Press [l] to load settings, align displays" << endl;
		ofDrawBitmapString(report.str(), 20, 20);
		
		manager.debugDraw(300, 300);
	}
	
	void keyReleased(int key) {
		
		if (key == 's') {
			manager.save2();
		}
		if (key == 'l') {
			// horizontal
			manager.load2("display.txt", ofxDisplayLayout::ALIGN_HORIZONTAL);
			
			// vertical
			// manager.load("display.txt", ofxDisplayLayout::ALIGN_VERTICAL);
		}
	}
};



#pragma mark -
#pragma mark main
int main(){
	ofSetupOpenGL(1024, 780, OF_WINDOW);
	ofRunApp(new ofApp());
}

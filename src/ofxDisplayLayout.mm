#include "ofxDisplayLayout.h"
#include "ofLog.h"
#include "ofAppRunner.h"
#include "ofGraphics.h"
#include "ofSystemUtils.h"

#import <Foundation/Foundation.h>

#pragma mark -
#pragma mark public

ofxDisplayLayout::ofxDisplayLayout() {
#ifndef TARGET_OSX
	ofSystemAlertDialog("Sorry! ofxDisplayLayout supports only MacOS only.");
#endif
}

bool ofxDisplayLayout::save(string filepath) const {
	
	/*!
		getting display ids
	 */
	const vector<unsigned int> display_ids = getDisplayIds();
	
	ofLogVerbose() << "ofxDisplayLayout found " << display_ids.size() << " displays." << endl;
	
	if (display_ids.size() < 2) {
		ofLogError() << "you don't need to arange display layout. aborted" << endl;
		return false;
	}
	
	
	/*!
	 writing to tile
	 */
	stringstream stream;
	
	auto create_report = [this, &stream]
						 (unsigned int display_id)
	{
		const ofRectangle bounds = getDisplayBounds(display_id);
		
		stringstream report;
		report << "[" << (isMainDisplay(display_id) ? "Main" : "Sub") << " Display]" << endl;
		report << "display id: " << display_id << endl;
		report << "display bounds: {"
			<< "x:" << bounds.x
			<< ", y:" << bounds.y
			<< ", w:" << bounds.width
			<< ", h:" << bounds.height
			<< "}" << endl;
		
		ofLogVerbose() << report.str();
		
		stream << display_id << endl;
	};
	
	for_each(begin(display_ids),
			 end(display_ids),
			 create_report);
	
	/*!
	 writing to tile
	 */
	ofLogVerbose() << "start saving current monitor order...";
	
	ofBuffer buf(stream.str());
	
	if (ofBufferToFile(filepath, buf)) {
		ofLogVerbose() << "succeeded!";
		ofLogVerbose() << "the display order is saved to: " << filepath << endl;
	}
	
	return true;
}

bool ofxDisplayLayout::load(string filepath, AlignmentDirection direction) const {
	
	/*!
		file check
	 */
	if (!ofFile::doesFileExist(filepath)) {
		ofLogVerbose() << filepath << " doesn't exist. aborted" << endl;
		return false;
	}
	
	/*!
		reading valid display id
	 */
	vector<unsigned int> display_ids;
	
	ofBuffer buf = ofBufferFromFile(filepath);
	ofBuffer::Lines lines = buf.getLines();
	
	for (ofBuffer::Line l = lines.begin(); l != lines.end(); ++l) {
		
		const string linestr = l.asString();
		
		if (linestr.empty()) continue;
		
		const unsigned int display_id = stoul(linestr);
		
		if (hasDisplay(display_id) == false) {
			ofLogVerbose() << "Aborted. couldn't found the display : " << display_id;
			return false;
		}
		
		display_ids.emplace_back(display_id);
	}
	
	/*!
		arrange
	 */
	return arrange(display_ids, direction);
}


void ofxDisplayLayout::debugDraw(int x, int y, float scale) {
	
	auto draw = [this, &scale]
				(unsigned int display_id)
	{
		ofRectangle rect = getDisplayBounds(display_id);
		
		ofPushMatrix();
		{
			ofScale(scale, scale);
			
			ofFill();
			ofSetColor(255, 0, 0, 100);
			ofDrawRectangle(rect);
			
			ofNoFill();
			ofSetColor(255, 0, 0);
			ofSetLineWidth(2);
			ofDrawRectangle(rect);
		}
		ofPopMatrix();
		
		if (isMainDisplay(display_id)) {
			ofDrawBitmapStringHighlight("Main",
										rect.getPosition() * scale,
										ofColor::red,
										ofColor::white);
		}
		
		ofSetColor(255);
		ofDrawBitmapString(ofToString(display_id),
						   rect.getPosition() * scale + 20);
	};
	
	const vector<unsigned int> display_ids = getDisplayIds();
	
	ofPushStyle();
	ofTranslate(x, y);
	for_each(begin(display_ids),
			 end(display_ids),
			 draw);
	ofPopStyle();
}


#pragma mark -
#pragma mark private

bool ofxDisplayLayout::isMainDisplay(unsigned int display_id) const {
	return CGMainDisplayID() == display_id;
}

bool ofxDisplayLayout::hasDisplay(unsigned int display_id) const {
	
	const vector<unsigned int> display_ids = getDisplayIds();
	
	return find(begin(display_ids),
				end(display_ids),
				display_id) != end(display_ids);
}

ofRectangle ofxDisplayLayout::getDisplayBounds(unsigned int display_id) const {
	
	const CGRect bounds = CGDisplayBounds(display_id);
	
	return ofRectangle(bounds.origin.x,
					   bounds.origin.y,
					   bounds.size.width,
					   bounds.size.height);
}

vector<unsigned int> ofxDisplayLayout::getDisplayIds() const {
	
	const unsigned int num_max_displays = 50;
	
	NSRect frame;
	CGDirectDisplayID displays[num_max_displays];
	CGDisplayCount num_displays;
	
	CGError err = CGGetOnlineDisplayList(num_max_displays, displays, &num_displays);
	vector<unsigned int> ids(num_displays);
	
	if (err != kCGErrorSuccess) {
		ofLogError() << "faild to get display ids.";
		return ids;
	}
	
	for (int i=0; i<num_displays; i++)
		ids[i] = displays[i];
	
	return ids;
}

size_t ofxDisplayLayout::getNumDisplay() const {
	return getDisplayIds().size();
}

bool ofxDisplayLayout::arrange(vector<unsigned int> display_ids, AlignmentDirection direction) const {
	
	// see also: Quartz Display Services Reference
	// https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/Quartz_Services_Ref/index.html
	
	if (direction >= NUM_ALIGNMENT_TYPES) {
		ofLogError() << "unknown alignment type. aborted";
		return false;
	}
	
	
	/*!
	 estimating the new origin for each display
	 */
	struct Display {
		
		Display(unsigned int _id, ofRectangle _bounds, ofPoint _origin)
		: id(_id)
		, old_bounds(_bounds)
		, new_origin(_origin)
		{}
		
		unsigned int id;
		ofRectangle old_bounds;
		ofPoint new_origin;
	};
	
	vector<Display> displays;
	
	for (int i=0; i<display_ids.size(); i++)
	{
		const unsigned int id = display_ids.at(i);
		const ofRectangle bounds = getDisplayBounds(id);
		
		ofPoint origin;
		
		if (i == 0) {
			// first display
			origin = ofPoint::zero();
		}
		else {
			// set origin as next to the previous display
			Display &display_prev = displays.at(i-1);
			
			origin = display_prev.new_origin;
			
			if (direction == ALIGN_HORIZONTAL) {
				origin.x += display_prev.old_bounds.width;
			}
			else if (direction == ALIGN_VERTICAL) {
				origin.y += display_prev.old_bounds.height;
			}
		}
		
		displays.emplace_back( Display(id, bounds, origin) );
	}
	
	
	/*!
		arrange!
	 */
	auto change_display_order = [](Display &display) {
		
		CGDisplayErr err;
		CGDisplayConfigRef configRef;
		
		CGBeginDisplayConfiguration(&configRef);
		
		err = CGConfigureDisplayOrigin(configRef,
									   (CGDirectDisplayID)display.id,
									   display.new_origin.x,
									   display.new_origin.y);
		
		if (err != kCGErrorSuccess) {
			
			ofLogError() << "display order arrangement falild on display: " << display.id;
			ofLogError() << "reason: " << err << endl;
			CGCancelDisplayConfiguration(configRef);
			return false;
		}
		
		else {
			ofLogVerbose()
				<< "Succeeded! Display " << display.id << " is set to the origin "
				<< "{x:" << display.new_origin.x << ", y:" << display.new_origin.y << "}";
			CGCompleteDisplayConfiguration(configRef, kCGConfigureForSession);
		}
	};
	
	try {
		for_each(begin(displays),
				 end(displays),
				 change_display_order);
		
	}
	catch (const exception& e) {
		ofLogError() << "Error: " << e.what();
		return false;
	}
	
	ofLogVerbose() << "display alignment done!";
	
	return true;
}
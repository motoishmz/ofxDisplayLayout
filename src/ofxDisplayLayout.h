#pragma once

#include <iostream>
#include <vector>
#include "ofRectangle.h"

using namespace std;

class ofxDisplayLayout{
	
public:
	
	typedef enum {
		ALIGN_HORIZONTAL = 0,
		ALIGN_VERTICAL,
		NUM_ALIGNMENT_TYPES
	} AlignmentDirection;
	
	ofxDisplayLayout();
	bool save(string filepath = "display.txt") const;
	bool load(string filepath = "display.txt", AlignmentDirection direction = ALIGN_HORIZONTAL) const;
	void debugDraw(int x, int y, float scale = 0.1);
	
private:
	
	bool arrange(vector<unsigned int> display_ids, AlignmentDirection direction) const;
	
	bool isMainDisplay(unsigned int display_id) const;
	bool hasDisplay(unsigned int display_id) const;
	ofRectangle getDisplayBounds(unsigned int display_id) const;
	vector<unsigned int> getDisplayIds() const;
	size_t getNumDisplay() const;
};


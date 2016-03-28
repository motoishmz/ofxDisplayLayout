#pragma once

#include <iostream>
#include <vector>
#include "ofRectangle.h"

using namespace std;

class ofxDisplayLayout{
	
public:
	
  typedef enum {
    UNKNOWN_DIRECTION = -1,
    ALIGN_HORIZONTAL = 0,
    ALIGN_VERTICAL,
    NUM_DIRECTIONS
  } Direction;

  ofxDisplayLayout();
  bool save(string filepath = "display.txt", ofxDisplayLayout::Direction direction = ALIGN_HORIZONTAL) const;
  bool load(string filepath = "display.txt", ofxDisplayLayout::Direction direction = ALIGN_HORIZONTAL) const;
  void debugDraw(int x, int y, float scale = 0.1);

  private:

  bool arrange(vector<unsigned int> display_ids, ofxDisplayLayout::Direction direction) const;

  bool isValidDirection(ofxDisplayLayout::Direction direction) const;
  bool isMainDisplay(unsigned int display_id) const;
  bool hasDisplay(unsigned int display_id) const;
  ofRectangle getDisplayBounds(unsigned int display_id) const;
  vector<unsigned int> getDisplayIds() const;
  size_t getNumDisplay() const;
};


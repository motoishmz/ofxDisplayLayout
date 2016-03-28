#pragma once

#include <iostream>
#include <vector>
#include "ofRectangle.h"

class ofxDisplayLayout{
	
public:
	
  typedef enum {
    UNKNOWN_DIRECTION = -1,
    ALIGN_HORIZONTAL = 0,
    ALIGN_VERTICAL,
    NUM_DIRECTIONS
  } Direction;

  ofxDisplayLayout();
  bool save(std::string filepath = "display.txt", ofxDisplayLayout::Direction direction = ALIGN_HORIZONTAL) const;
  bool load(std::string filepath = "display.txt", ofxDisplayLayout::Direction direction = ALIGN_HORIZONTAL) const;
  void debugDraw(int x, int y, float scale = 0.1);

private:

  std::vector<unsigned int> getDisplayIds() const;
  bool arrange(std::vector<unsigned int> display_ids, ofxDisplayLayout::Direction direction) const;
  
  bool isValidDirection(ofxDisplayLayout::Direction direction) const;
  bool isMainDisplay(unsigned int display_id) const;
  bool hasDisplay(unsigned int display_id) const;
  ofRectangle getDisplayBounds(unsigned int display_id) const;
  size_t getNumDisplay() const;
};


inline ofxDisplayLayout::ofxDisplayLayout() {
#ifndef TARGET_OSX
  ofSystemAlertDialog("Sorry! ofxDisplayLayout supports only MacOS.");
#endif
}

inline bool ofxDisplayLayout::isValidDirection(ofxDisplayLayout::Direction direction) const {
  return UNKNOWN_DIRECTION < direction || direction < NUM_DIRECTIONS;
}

inline bool ofxDisplayLayout::isMainDisplay(unsigned int display_id) const {
  return CGMainDisplayID() == display_id;
}

inline bool ofxDisplayLayout::hasDisplay(unsigned int display_id) const {
  const vector<unsigned int> display_ids = getDisplayIds();
  return std::find(begin(display_ids),
                   end(display_ids),
                   display_id) != end(display_ids);
}

inline ofRectangle ofxDisplayLayout::getDisplayBounds(unsigned int display_id) const {
  const CGRect bounds = CGDisplayBounds(display_id);
  return ofRectangle(bounds.origin.x,
                     bounds.origin.y,
                     bounds.size.width,
                     bounds.size.height);
}

inline size_t ofxDisplayLayout::getNumDisplay() const {
  return getDisplayIds().size();
}
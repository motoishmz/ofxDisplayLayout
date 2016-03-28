#include "ofxDisplayLayout.h"
#include "ofLog.h"
#include "ofAppRunner.h"
#include "ofGraphics.h"
#include "ofSystemUtils.h"

#import <Foundation/Foundation.h>

#pragma mark -
#pragma mark public


bool ofxDisplayLayout::save(std::string filepath,
                            ofxDisplayLayout::Direction direction) const {
  
  const std::vector<unsigned int> display_ids = getDisplayIds();
  
  ofLogVerbose() << "ofxDisplayLayout found " << display_ids.size() << " displays." << endl;
  
  if (display_ids.size() < 2) {
    ofLogError() << "you don't need to arange display layout. aborted" << endl;
    return false;
  }
  
  //! sorting display order by alignment direction
  if (!isValidDirection(direction)) {
    ofLogError() << __PRETTY_FUNCTION__ << " invalid direction " << direction << "is passed. aborted";
    return false;
  }
  
  struct Display { unsigned int id; ofRectangle bounds; };
  std::vector<Display> displays;
  for (const auto & display_id: display_ids) {
    Display display;
    display.id = display_id;
    display.bounds = getDisplayBounds(display_id);
    displays.emplace_back(display);
  }
  
  std::sort(begin(displays),
            end(displays),
            [&](Display & lhs, Display & rhs){
              assert(direction == ALIGN_VERTICAL || direction == ALIGN_HORIZONTAL);
              return (direction == ALIGN_HORIZONTAL)
                ? (lhs.bounds.x < rhs.bounds.x)
                : (lhs.bounds.y < rhs.bounds.y);
            });
  

  //! creating reports
  std::ostringstream stream;
  std::for_each(begin(displays),
                end(displays),
                [this, &stream](Display & display){
                  std::ostringstream report;
                  report << "[" << (isMainDisplay(display.id) ? "Main" : "Sub") << " Display]" << endl;
                  report << "display id: " << display.id << endl;
                  report << "display bounds: {"
                  << "x:" << display.bounds.x
                  << ", y:" << display.bounds.y
                  << ", w:" << display.bounds.width
                  << ", h:" << display.bounds.height
                  << "}" << endl;
                  
                  ofLogVerbose() << report.str();
                  
                  stream << display.id << endl; // storing only display id
                });
  
  //! writing to tile
  ofLogVerbose() << "start saving current monitor order...";
  
  ofBuffer buf(stream.str());
  
  if (ofBufferToFile(filepath, buf)) {
    ofLogVerbose() << "succeeded!";
    ofLogVerbose() << "the display order is saved to: " << filepath << endl;
  }
  
  return true;
}

bool ofxDisplayLayout::load(std::string filepath,
                            ofxDisplayLayout::Direction direction) const {
  
  //! file check
  if (!ofFile::doesFileExist(filepath)) {
    ofLogVerbose() << filepath << " doesn't exist. aborted" << endl;
    return false;
  }
  
  //! direction check
  if (!isValidDirection(direction)) {
    ofLogError() << __PRETTY_FUNCTION__ << " invalid direction " << direction << "is passed. aborted";
    return false;
  }
  
  //! reading valid display id
  std::vector<unsigned int> display_ids;
  
  ofBuffer buf = ofBufferFromFile(filepath);
  ofBuffer::Lines lines = buf.getLines();
  
  for (ofBuffer::Line l = lines.begin(); l != lines.end(); ++l) {
    
    const std::string linestr = ofTrim(l.asString());
    
    if (linestr.empty()) continue;
    
    const unsigned int display_id = std::stoul(linestr);
    
    if (hasDisplay(display_id) == false) {
      ofLogVerbose() << "Aborted. couldn't found the display : " << display_id;
      return false;
    }
    
    display_ids.emplace_back(display_id);
  }
  
  return arrange(display_ids, direction);
}


void ofxDisplayLayout::debugDraw(int x, int y, float scale) {
  
  auto draw = [this, &scale](unsigned int display_id) {
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
    
    const ofPoint pos = rect.getPosition() * scale;
    
    if (isMainDisplay(display_id)) {
      ofDrawBitmapStringHighlight("Main",
                                  pos,
                                  ofColor::red,
                                  ofColor::white);
    }
    
    ofSetColor(255);
    ofDrawBitmapString(ofToString(display_id), pos.x+20, pos.y+20);
    ofDrawBitmapString(ofToString(pos), pos.x+20, pos.y+20);
  };
  
  const std::vector<unsigned int> display_ids = getDisplayIds();
  
  ofPushStyle();
  ofTranslate(x, y);
  for_each(begin(display_ids),
           end(display_ids),
           draw);
  ofPopStyle();
}


#pragma mark - private

vector<unsigned int> ofxDisplayLayout::getDisplayIds() const {
  
  const unsigned int num_max_displays = 50;
  
  NSRect frame;
  CGDirectDisplayID displays[num_max_displays];
  CGDisplayCount num_displays;
  
  CGError err = CGGetOnlineDisplayList(num_max_displays, displays, &num_displays);
  std::vector<unsigned int> ids(num_displays);
  
  if (err != kCGErrorSuccess) {
    ofLogError() << "faild to get display ids.";
    return ids;
  }
  
  for (int i=0; i<num_displays; i++)
    ids[i] = displays[i];
  
  return ids;
}

bool ofxDisplayLayout::arrange(std::vector<unsigned int> display_ids,
                               ofxDisplayLayout::Direction direction) const {
  
  // see also: Quartz Display Services Reference
  // https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/Quartz_Services_Ref/index.html
  
  if (!isValidDirection(direction)) {
    ofLogError() << __PRETTY_FUNCTION__ << " invalid direction " << direction << "is passed. aborted";
    return false;
  }
  
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
  
  std::vector<Display> displays;
  
  for (int i=0; i<display_ids.size(); i++) {
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
    
    displays.emplace_back(Display(id, bounds, origin));
  }
  
  auto change_display_order = [](Display &display) {
    
    CGDisplayErr err;
    CGDisplayConfigRef configRef;
    
    CGBeginDisplayConfiguration(&configRef);
    
    err = CGConfigureDisplayOrigin(configRef,
                                   static_cast<CGDirectDisplayID>(display.id),
                                   display.new_origin.x,
                                   display.new_origin.y);
    
    if (err != kCGErrorSuccess) {
      CGCancelDisplayConfiguration(configRef);
      ofLogError() << "display order arrangement falild on display: " << display.id;
      ofLogError() << "reason: " << err << endl;
      return false;
    }
    else {
      CGCompleteDisplayConfiguration(configRef, kCGConfigureForSession);
      ofLogVerbose()
      << "Succeeded! Display " << display.id << " is set to the origin "
      << "{x:" << display.new_origin.x << ", y:" << display.new_origin.y << "}";
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
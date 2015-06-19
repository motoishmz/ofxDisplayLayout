## ofxDisplayLayout grabs the display unique ID, and aligns your displays vertically/horizontally

	!!!: This addon supports only Mac OS.
	!!!: Less than OF 0.9.0 is not supported since this addon uses C++11 features.

(before alignment...)

![](https://41.media.tumblr.com/ab739141c067b09596b15f1c4231bb29/tumblr_nq6mdiK2lC1s2up8jo1_540.png)

ofxDisplayLayout::*ALIGN_HORIZONTAL*

![](https://41.media.tumblr.com/55d5d0a387c0335654baca85365d6a2f/tumblr_nq6mdiK2lC1s2up8jo3_400.png)

ofxDisplayLayout::*ALIGN_VERTICAL*

![](https://36.media.tumblr.com/0489db34974f70d866b67c9b0f44c3ce/tumblr_nq6mdiK2lC1s2up8jo2_400.png)


## Use case
- When you want to make sure the order of displays connected to your Mac - for an installation which wakes up/shuts down automatically.


## Example
- Arrange the display layout from SystemPreference by hand
- Launch the example in this repo
- Press [s] to save the order of the displays. `displas.txt` will be saved to the `bin/data` dir. It keeps the display order
- Rearrange the display layout from SystemPreference by hand
- Press [l] to load


## Demo movie
- [https://instagram.com/p/4GhGW0LMyA/](https://instagram.com/p/4GhGW0LMyA/)
- [https://instagram.com/p/4GhVAjrMyL/](https://instagram.com/p/4GhVAjrMyL/)
- [https://instagram.com/p/4GhyxgrMyw/](https://instagram.com/p/4GhyxgrMyw/)


## Testers needed!

ofxDisplayLayout is tested under the environment:
	
	MacBook Pro (Retina, 15-inch, Mid 2014)
	OS X 10.10.3 Yosemite
	+
	External monitor * 2

Please send me a report if this addon works fine on...

- MacPro + more than 3 monitors + wakes up/shut down automatically
- Matrox TripleHead
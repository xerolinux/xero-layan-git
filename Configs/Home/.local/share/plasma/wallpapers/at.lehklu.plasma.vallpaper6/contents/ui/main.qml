/*
 *  Copyright 2025  Werner Lechner <werner.lechner@lehklu.at>
 */

import QtQuick
import QtQuick.Controls
import org.kde.kquickcontrolsaddons
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.mediaframe
import org.kde.plasma.private.pager

import Qt5Compat.GraphicalEffects

import "../js/v.js" as VJS

WallpaperItem { /*MOD*/
	id: _Root

  property var config: configuration.vallpaper6 /*MOD*/
  // Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground /*MOD*/
  property var prefixActionText: '<Vallpaper> ' /*MOD*/  

  property var devShowInfo: false

  property var previousConfigJson
  property var configAdapter

  property var activeImage
  property bool repeaterReady: false

  Plasmoid.contextualActions: [
    PlasmaCore.Action {
        text: prefixActionText + "Open image"
        icon.name: "document-open"
        priority: Plasmoid.LowPriorityAction
        visible: true
        enabled: activeImage.mediaframe.count>0
        onTriggered: { _Canvas.actionOpen(); }
    },
    PlasmaCore.Action {
        text: prefixActionText + "Next image"
        icon.name: "user-desktop"
        priority: Plasmoid.LowPriorityAction
        visible: true
        enabled: activeImage.mediaframe.count>1 || !activeImage.cache
        onTriggered: { _Canvas.actionNext(); }
    }
  ]    

  onConfigChanged: {

    const configJson = JSON.stringify(config);
    if(previousConfigJson==configJson) { return;}
    //<--


    previousConfigJson=configJson;
    configAdapter = new VJS.PlasmacfgAdapter(config);
  }

	PagerModel {
    id: _Pager

    enabled: _Root.visible
    pagerType: PagerModel.VirtualDesktops

    Component.onCompleted: { 

      _ImageRepeater.model = count + 1; // +1 =^= shared image
    }

    onCurrentPageChanged: { 
      
      if( ! repeaterReady) { return; }
	    //<--


      const newActiveImage = _ImageRepeater.imageFor(_Pager.currentPage);       
      newActiveImage.refresh();
      activeImage = newActiveImage;
    }
	}

  Timer {
	  id: _Timer
    interval: 1000 * 1 // sec
    repeat: true
    running: true
    onTriggered: { 

      if( ! activeImage) { return; }
	    //<--            


      activeImage.refresh();
    }
  }  

  // C A N V A S - - - - - - - - - - - - - - - - - -
  // C A N V A S - - - - - - - - - - - - - - - - - -
  // C A N V A S - - - - - - - - - - - - - - - - - -  
  Rectangle {
    id: _Canvas

    anchors.fill: parent          
    color: activeImage.slotCfg.background

    Repeater {
	    id: _ImageRepeater

      onModelChanged: {

        if(model==0) { return; };
        //<--


        repeaterReady=true; 

        activeImage = _ImageRepeater.imageFor(_Pager.currentPage);                 
        activeImage.refresh();
      }

      function imageFor($pageNo) {

        const deskCfg = configAdapter.findAppropiateDeskCfgFor_pageNo($pageNo);

        const imageIdx = deskCfg.deskNo==VJS.DESKNO_GLOBAL?count-1:$pageNo;

        return itemAt(imageIdx);
      }

      // I M A G E - - - - - - - - - - - - - - - - - -
      // I M A G E - - - - - - - - - - - - - - - - - -
      // I M A G E - - - - - - - - - - - - - - - - - -      
      Image {
        anchors.fill: parent          

        visible: false // displayed through Graphical effects

        //  this property sets the maximum number of pixels stored for the loaded image so that large images do not use more memory than necessary. 
        //  If only one dimension of the size is set to greater than 0, the other dimension is set in proportion to preserve the source image's aspect ratio. (The fillMode is independent of this.)
        sourceSize.width: width 

        asynchronous: true
        autoTransform: true

        property var slotCfg

        property string infoText
		    property var timestampFetched
        property var mediaframe: MediaFrame {}

		    Component.onCompleted: { refresh(); }

		    function refresh() {

          if( ! configAdapter) { return; }
	        //<--


          const deskCfg = configAdapter.findAppropiateDeskCfgFor_pageNo(_Pager.currentPage);
          const appropiateSlotCfg = deskCfg.findAppropiateSlotCfgFor_now();

          if(appropiateSlotCfg!=slotCfg)
          {
            source = "";infoText = source;
			      timestampFetched = -1;
			      slotCfg = appropiateSlotCfg;

			      anchors.topMargin =     slotCfg.paddingTop;
            anchors.bottomMargin =  slotCfg.paddingBottom;
            anchors.leftMargin =    slotCfg.paddingLeft;
            anchors.rightMargin =   slotCfg.paddingRight;              
			    
            fillMode = slotCfg.fillMode;

            mediaframe.clear();
			      mediaframe.random = slotCfg.shuffle;
            for(let $$path of slotCfg.imagesources)
			      {
              const safePath = VJS.AS_URISAFE($$path);
				      mediaframe.add(safePath, true); // path, recursive
			      }
          }


          imgFetchNext();              
		    }

		    function imgFetchNext($force=false) {

          if( ! $force &&
              ! (timestampFetched===-1) &&
              (slotCfg.interval==0 || (Date.now() < (timestampFetched + slotCfg.interval*1000)))
          ) { return; }
          //<--          

          if(mediaframe.count === 0) { return; }
          //<--


          mediaframe.get($$path => {

            cache = ! $$path.startsWith('http');

            if($$path.startsWith('http'))
            {
              source = ""; // trigger reload
            }
            else if( ! $$path.startsWith('file://'))
            {
              $$path = 'file://' + $$path;
            }

            source = $$path;infoText = source;                
            timestampFetched = Date.now();
			    });
		    }
	    }
      // - - - - - - - - - - - - - I M A G E
      // - - - - - - - - - - - - - I M A G E
      // - - - - - - - - - - - - - I M A G E      
    }

    // D I S P L A Y C H A I N - - - - - - - - - - - - - - - - - -
    // D I S P L A Y C H A I N - - - - - - - - - - - - - - - - - -
    // D I S P L A Y C H A I N - - - - - - - - - - - - - - - - - -    
    Desaturate {
	    id: dcDesaturate

      source: activeImage
      anchors.fill: activeImage
      visible: activeImage.source!=""

      desaturation: activeImage.slotCfg.desaturate
    }

    FastBlur {
	    id: dcBlur

      source: dcDesaturate
      anchors.fill: dcDesaturate
      visible: dcDesaturate.visible

      radius: activeImage.slotCfg.blur * 100
    }

    ColorOverlay {
	    id: dcColorOverlay

      source: dcBlur
      anchors.fill: dcBlur
      visible: dcBlur.visible

      color: activeImage.slotCfg.colorizeValue
    }
    // - - - - - - - - - - - - - D I S P L A Y C H A I N
    // - - - - - - - - - - - - - D I S P L A Y C H A I N
    // - - - - - - - - - - - - - D I S P L A Y C H A I N    

    Rectangle {
      visible: devShowInfo
	    width: labelInfo.contentWidth
      height: labelInfo.contentHeight
      anchors.top: parent.top
      anchors.left: parent.left
      color: '#ff1d1d85'

	    Label {
		    id: labelInfo
  	    color: "#ffffffff"
  	    text: activeImage.infoText
      }
    }

    function actionNext() {

	    activeImage.imgFetchNext(true);
    }

    function actionOpen() {

	    Qt.openUrlExternally(activeImage.source)
    }

/* Dev *
    Rectangle {
      id: _LogBackground
      color: '#00ff0000'                  
      anchors.fill: parent

      ScrollView {
        anchors.fill: parent      
        background: Rectangle {
          color: '#0000ff00'
        }      

        TextArea {
          id: _Log
          readOnly: true
          
          background: Rectangle {
            color: '#88ffffff'
          }
          wrapMode: TextEdit.Wrap
          horizontalAlignment: TextEdit.AlignRight

          property int autoclear:0

          function clear() {

            text='';
            autoclear=0;
          }

          function sayo($o) {

        	  say(JSON.stringify($o));
          }

          function say($text) {

              text=text+'\n'+$text;
              autoclear++;

              if(autoclear>30)
              {
                  clear();
              }
          }
        }
    }
  }
/* /Dev */    
  }
  // - - - - - - - - - - - - - C A N V A S
  // - - - - - - - - - - - - - C A N V A S
  // - - - - - - - - - - - - - C A N V A S  


  MouseArea {
    anchors.fill: parent

    onPressAndHold: { _Canvas.actionNext(); }
    onDoubleClicked: { _Canvas.actionOpen(); }
  }
}

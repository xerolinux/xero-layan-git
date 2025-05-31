/*
 *  Copyright 2025  Werner Lechner <werner.lechner@lehklu.at>
 */

const DESKNO_GLOBAL = 0;
const DESKNO_GLOBAL_NAME = '*';

const SLOTMARKER_DEFAULT = '00:00';

const TIMESLOT_DEFAULT_jsonstr = `{
	"slotmarker": "` + SLOTMARKER_DEFAULT + `",
	"background": "#1d1d85",
	"paddingTop": 0,
	"paddingBottom": 0,
	"paddingLeft": 0,
	"paddingRight": 0,
	"fillMode": 1,
	"desaturate": 0,
	"blur": 0,
	"colorize": 0,
	"colorizeColor": "#ffffff",
	"colorizeValue": "#00ffffff",
	"interval": 0,
	"shuffle": 0,
	"imagesources": []
}`;

const DESKCFG_DEFAULT_jsonstr = `{
  "deskNo": ` + DESKNO_GLOBAL + `, 
  "timeslots": { 
    "` + SLOTMARKER_DEFAULT + `": ` + TIMESLOT_DEFAULT_jsonstr + ` 
    }
  }`;

// P l a s m a c f g A d a p t e r  
// P l a s m a c f g A d a p t e r  
// P l a s m a c f g A d a p t e r  
class PlasmacfgAdapter {

	constructor($plasmacfg_jsonstrs, $fOnCfgChanged=undefined) {

    this.deskCfgs = [];
		this.fOnCfgChanged = $fOnCfgChanged;

    if($plasmacfg_jsonstrs.length==0)
    {
			this.addCfg(new DeskCfg(DESKCFG_DEFAULT_jsonstr));
    }
    else
    {
      for(const $$deskCfg_jsonstr of $plasmacfg_jsonstrs)
      {
        this.addCfg(new DeskCfg($$deskCfg_jsonstr));
      }
    }
	}

  propagateCfgChange_afterAction($fAction=undefined) {

  	if($fAction) { $fAction(); }

		if(this.fOnCfgChanged) 
    { 
      const newCfgJSONs=[];

      for(const $$cfg of this.getCfgs())
      {
        newCfgJSONs.push(JSON.stringify($$cfg));
      }

      this.fOnCfgChanged(newCfgJSONs); 
    }
	}

	newCfgForDeskNo_cloneDeskNo($newDeskNo, $cloneDeskNo) {

		this.addCfg(this.getCfgForDeskNo($cloneDeskNo).cloneAs($newDeskNo));
		this.propagateCfgChange_afterAction();
	}

  deleteCfgDeskNo($deskNo) {

  	this.deskCfgs.splice($deskNo, 1);
		this.propagateCfgChange_afterAction();
	}

  getCfgs() {

  	    // ev. sparse array
    return this.deskCfgs.filter(($$cfg) => { return $$cfg!==undefined});
	}

	addCfg($cfg) {

		this.deskCfgs[$cfg.deskNo] = $cfg;
	}

	getCfgForDeskNo($deskNo) {

  	return this.deskCfgs[$deskNo];
 	}

	findAppropiateDeskCfgFor_pageNo($pageNo) {
    
    const deskNo = $pageNo+1;

  	return this.deskCfgs[deskNo]!==undefined?this.deskCfgs[deskNo]:this.deskCfgs[DESKNO_GLOBAL];
 	}

	atCfg_newTimeslotForMarker_cloneMarker($deskCfg, $slotmarker, $cloneSlotmarker) {

		$deskCfg.timeslots[$slotmarker] = $deskCfg.timeslots[$cloneSlotmarker].cloneAs($slotmarker);
		this.propagateCfgChange_afterAction();
	}

	atCfg_deleteTimeslot($deskCfg, $slotmarker) {

		delete $deskCfg.timeslots[$slotmarker];
		this.propagateCfgChange_afterAction();
	}
}

// D e s k t o p C f g
// D e s k t o p C f g
// D e s k t o p C f g
class DeskCfg {

	constructor($json) {

		const o = JSON.parse($json);

		Object.assign(this, o);


		const timeslotKeys = Object.keys(this.timeslots);
		for(const $$key of timeslotKeys)
		{
			this.timeslots[$$key] = new TimeslotCfg(this.timeslots[$$key]); // replace object with TimeslotCfg instance
		}
	}

	cloneAs($newDeskNo) {

		const clone = new DeskCfg(JSON.stringify(this));
		clone.deskNo = $newDeskNo;

		return clone;
	}

	getTimeslotForSlotmarker($slotmarker) {

		return this.timeslots[$slotmarker];
	}

	findAppropiateSlotCfgFor_now() {

		const d = new Date();
		const nowSlotmarker = ('00' + d.getHours()).slice(-2) + ':' + ('00' + d.getMinutes()).slice(-2);

		const orderedSlotmarkers = Object.keys(this.timeslots).sort();

		let appropiateSlotmarker = SLOTMARKER_DEFAULT;

		for(const $$slotmarker of orderedSlotmarkers)
		{
			if($$slotmarker > nowSlotmarker)
			{
				break;
			}

			appropiateSlotmarker = $$slotmarker;
		}

		return this.timeslots[appropiateSlotmarker];
	}

	getOrderedTimeslots() {

		const keys = Object.keys(this.timeslots).sort();

		const result = [];

		for(const $$key of keys)
		{
			result.push(this.timeslots[$$key]);
		}

		return result;
	}
}

// T i m e s l o t C f g
// T i m e s l o t C f g
// T i m e s l o t C f g
class TimeslotCfg {

	constructor($template) {

		Object.assign(this, $template);
	}

	cloneAs($slotmarker) {

		const clone = new TimeslotCfg(this);
		clone.slotmarker = $slotmarker;

		return clone;
	}
}


// G l o b a l   f u n c t i o n s
// G l o b a l   f u n c t i o n s
// G l o b a l   f u n c t i o n s
const AS_URISAFE = function($text, $asUriSafe=true) {

  const target = $asUriSafe?"%":"%25";
  const replacement = $asUriSafe?"%25":"%";

  const result = $text.replace(new RegExp(target, "g"), replacement);

  return result;
}
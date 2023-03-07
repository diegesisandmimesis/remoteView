#charset "us-ascii"
//
// remoteView.t
//
#include <adv3.h>
#include <en_us.h>

// Module ID for the library
remoteViewModuleID: ModuleID {
        name = 'Remote View Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

// Anonymous preinit object, adds all RemoteView instances to their
// parent objects.
PreinitObject
	execute() {
		forEachInstance(RemoteView, function(o) {
			if(o.location == nil) return;
			o.location.addView(o);
		});
		forEachInstance(RemoteViewConnector, function(o) {
			if(o.locationList == nil) return;
			o.locationList.forEach(function(rm) {
				rm.addRemoteViewConnector(o);
			});
			
		});
	}
;

// Class to hold our viewed-through-connector descriptions.
class RemoteView: object
	connector = nil
	desc = nil
;

modify Room
	_remoteViewConnectors = nil

	addRemoteViewConnector(v) {
		if((v == nil) || !v.ofKind(RemoteViewConnector))
			return(nil);
		if(_remoteViewConnectors == nil)
			_remoteViewConnectors = new Vector();
		_remoteViewConnectors.append(v);
		return(true);
	}

	listRemoteContents(otherLocation) {
		_remoteViewLocation = otherLocation;
		try {
			lookAround(gActor,
				LookListSpecials | LookListPortables);
		}
		finally {
			_remoteViewLocation = nil;
		}
	}

	adjustLookAroundTable(tab, pov, actor) {
		inherited(tab, pov, actor);

		if(_remoteViewConnectors == nil)
			return;

		if(_remoteViewLocation != nil)
			return;

		tab.keysToList().forEach(function(o) {
			if(!o.isIn(actor.location))
				tab.removeElement(o);
		});
	}
;

class RemoteViewConnector: SenseConnector, Fixture
	connectorMaterial = adventium
	dobjFor(LookThrough) {
		verify() {}
		check() {}
		action() {
			local otherLocation;

			connectorMaterial = glass;
			if(gActor.isIn(locationList[1]))
				otherLocation = locationList[2];
			else
				otherLocation = locationList[1];

			gActor.location.listRemoteContents(otherLocation);
		}
	}
;

modify Thing
	_remoteViewLocation = nil
	_views = nil

	addView(v) {
		if((v == nil) || !v.ofKind(RemoteView))
			return;
		if(_views == nil) _views = new Vector();
		_views.append(v);
	}

	matchView() {
		local l, r;

		if(_views == nil) return(nil);
		r = nil;
		_views.forEach(function(o) {
			if(r != nil) return;
			if(o.connector == nil) return;
			l = o.connector.locationList;
			if(l == nil) return;
			if((gActor.isIn(l[1]) && isIn(l[2]))
				|| (gActor.isIn(l[2]) && isIn(l[1]))) {
				r = o;
				return;
			}
		});
		return(r);
	}

	adjustLookAroundTable(tab, pov, actor) {
		inherited(tab, pov, actor);
		if(_remoteViewLocation != nil) {
			tab.keysToList().forEach(function(o) {
				if(!o.isIn(_remoteViewLocation))
					tab.removeElement(o);
			});
		}
	}

	remoteBasicExamine() {
		local r;

		r = matchView();
		if(r != nil) {
			"<<r.desc>> ";
			return(true);
		}
		if(propDefined(&remoteDesc)) {
			remoteDesc(getPOVDefault(gActor));
			return(true);
		}
		return(nil);
	}

	// This is just a cut and paste of Thing.basicExamine() with the
	// first stanza of the conditional broken out into a different
	// method.
	basicExamine() {
		local info, t;

		info = getVisualSenseInfo();
		t = info.trans;
		if(getOutermostRoom()
			!= getPOVDefault(gActor).getOutermostRoom()
			&& remoteBasicExamine()) {
			// empty case
		} else if(t == obscured && propDefined(&obscuredDesc)) {
			obscuredDesc(info.obstructor);
		} else if(t == distant && propDefined(&distantDesc)) {
			distantDesc;
		} else if(canDetailsBeSensed(sight, info,
			getPOVDefault(gActor))) {
			if(useInitDesc())
				initDesc;
			else
				desc;
			described = true;
			examineStatus();
		} else if(t == obscured) {
			defaultObscuredDesc(info.obstructor);
		} else if(t == distant) {
			defaultDistantDesc;
		}
	}
;

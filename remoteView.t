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

modify playerActionMessages
	remoteViewFailure = '{You/he} can\'t look through that. '
;

// Anonymous preinit object, adds all RemoteView instances to their
// parent objects and sets up RemoteViewConnector instances.
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
	// Property to hold any remote view connectors that we're part of.
	_remoteViewConnectors = nil

	// Called by the preinit object, we make a note of any remote view
	// connectors that we're on one end of.
	addRemoteViewConnector(v) {
		if((v == nil) || !v.ofKind(RemoteViewConnector))
			return(nil);

		// Create a new vector for our connectors if we don't already
		// have one.
		if(_remoteViewConnectors == nil)
			_remoteViewConnectors = new Vector();

		// Add the connector.
		_remoteViewConnectors.append(v);

		return(true);
	}

	// Look around ANOTHER location FROM the current one.
	// We do it this way because once the sense connector is
	// transparent then we'll otherwise want to describe everything in
	// both locations.
	remoteViewLister(otherLocation) {
		_remoteViewLocation = otherLocation;
		try {
			lookAround(gActor,
				LookListSpecials | LookListPortables);
		}
		finally {
			_remoteViewLocation = nil;
		}
	}

	// Look around the room, unless we're in the middle of
	// try to look around a remote location.
	adjustLookAroundTable(tab, pov, actor) {
		inherited(tab, pov, actor);

		// If we don't have any connectors, everything we need
		// to do was already done by the inherited() above.
		if(_remoteViewConnectors == nil)
			return;

		// If we're looking around a remote location, we don't need to
		// look around this location.
		if(_remoteViewLocation != nil)
			return;

		tab.keysToList().forEach(function(o) {
			if(!o.isIn(actor.location))
				tab.removeElement(o);
		});
	}
;

class RemoteViewConnector: SenseConnector, Fixture
	// By default, the sense connector is bi-directional.  If this
	// flag is boolean true, then the connector works from the
	// first location to the second, but not from the second to the first.
	oneWay = nil

	// If we're one-way, then this is the failure message to display
	// when the player tries to >LOOK THROUGH us the other way.
	oneWayFailure = nil

	// Text to display (via reportBefore() and reportAfter())
	// when the player does a >LOOK THROUGH the connector.
	prefix = nil
	suffix = nil

	// Connector starts out totally opaque.
	connectorMaterial() {
		if(_remoteViewToggle != true) return(adventium);
		if(oneWay == true) {
			if(gActor.isIn(locationList[1]))
				return(glass);
			else
				return(adventium);
		}
		return(glass);
	}

	_remoteViewToggle = nil

	// We inherit locationList from MultiLoc via SenseConnector,
	// but ours always needs to be exactly two elements long:  the
	// two locations connected by the remote view connector.
	// locationList = static [ roomOne, roomTwo ]

	dobjFor(LookThrough) {
		verify() {
			if(!gActor.isIn(locationList[1])) {
				if(oneWayFailure)
					illogicalNow(oneWayFailure);
				else
					illogicalNow(&remoteViewFailure);
			}
		}
		check() {}
		action() {
			local otherLocation;

			// Mark the connector as visually transparent.
			//connectorMaterial = glass;
			_remoteViewToggle = true;

			// Figure out which location in our locationList
			// the current actor ISN'T in.
			if(gActor.isIn(locationList[1]))
				otherLocation = locationList[2];
			else 
				otherLocation = locationList[1];

			if(prefix) reportBefore(prefix);
			if(suffix) reportAfter(suffix);

			// Look around the OTHER location FROM THIS ONE.
			gActor.location.remoteViewLister(otherLocation);
		}
	}
;

modify Thing
	_remoteViewLocation = nil
	_views = nil

	// Called by the preinit object.  We add RemoteView instances
	// to our view list.
	addView(v) {
		if((v == nil) || !v.ofKind(RemoteView))
			return;
		if(_views == nil) _views = new Vector();
		_views.append(v);
	}

	// See if we have a RemoteView that matches the current
	// situation.
	matchView() {
		local l, r;

		// No views, nothing to do, bail.
		if(_views == nil)
			return(nil);

		// Go through our list of views to see if we match any.
		r = nil;

		_views.forEach(function(o) {
			// We already got a match, just return.
			if(r != nil)
				return;

			// We need a connector.
			if(o.connector == nil)
				return;
	
			// The connector needs to have a location list.
			l = o.connector.locationList;
			if(l == nil)
				return;

			// The location list will have at least two locations
			// (the two locations connected by the connector).
			// We now check to see if this object is in one and
			// the current actor is in the other.  If they are,
			// then that's a match for the connector, so
			// we mark the view as a match.
			if(gActor.isIn(l[1]) && isIn(l[2])) {
				r = o;
				return;
			}
			if(oneWay != true)
				return;

			if(gActor.isIn(l[2]) && isIn(l[1])) {
				r = o;
				return;
			}
		});

		// Return our match, if any.
		return(r);
	}

	// If we're in the process of looking into a remote location,
	// exclude anything that's NOT in that remote location.  This
	// is necessary because the sense connector is transparent, so the
	// sense table contains things in multiple locations.
	adjustLookAroundTable(tab, pov, actor) {
		inherited(tab, pov, actor);
		if(_remoteViewLocation != nil) {
			tab.keysToList().forEach(function(o) {
				if(!o.isIn(_remoteViewLocation))
					tab.removeElement(o);
			});
		}
	}

	// Method for remote viewing.
	// In the stock adv3 library the last stanza (testing remoteDesc)
	// is part of the first conditional in basicExamine().
	remoteBasicExamine() {
		local r;

		// See if we have a matching view for this object.
		r = matchView();

		// We have a match, so display it and return.
		if(r != nil) {
			"<<r.desc>> ";
			return(true);
		}

		if(propDefined(&remoteDesc)) {
			remoteDesc(getPOVDefault(gActor));
			return(true);
		}

		// We had no matching RemoteView and no remoteDesc defined,
		// report failure (to allow one of the other cases in
		// basicExamine() output something).
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

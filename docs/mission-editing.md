---
title: Mission Editing Guide
---

# Basics

1. Visit the "\#gb-modding" channel in the [official GROUND BRANCH Discord](https://discord.com/invite/9pp3TrT). The mission editor guide can be found in the pinned posts.
2. This video playlist provides an introduction to the editor: <https://www.youtube.com/playlist?list=PLle5osICJhZJwHxGOb1iBXoyu_uk9yXMY>. 
3. For each mission type we need AI spawns. The "AI priority" field is not used, instead
we add a "Group\<N\>" tag, where *N* is a natural number greater-than 1.
4. For each mission type we need insertion points and extraction points.

# Suggested order

1. Create "Kill Confirmed"
2. Create "Break Out" based on "Kill Confirmed".
3. Create "Kill Confirmed (Semi-Permissive, LowViz)" based on "Kill Confirmed".
4. Generate "Kill Confirmed (Semi-Permissive)" via script.
5. Create "Security Detail (Semi-Permissive, LowViz)" and "Asset Extraction (Semi-Permissive, LowViz)" based on "Kill Confirmed (Semi-Permissive, LowViz)".
6. Generate "Security Detail/Asset Extraction (Semi-Permissive)" via script.
7. Create "Security Detail" and "Asset Extraction" based on the "(Semi-Permissive, LowViz)" variants.

# Mission-type specific notes

## Kill Confirmed

- Add hostile AI spawn points with "Group<N>" tags. Using the kits from "EurAsi" or "MidEas".
- Add HVT AI spawns tagged as "HVT". Using the "HVT_*" kits from "EurAsi" or "MidEas".

## Kill Confirmed (Semi-Permissive, LowViz)

Start with a copy of "Kill Confirmed".

- Change the kits from "EurAsi"/"MidEas" to "Narcos" kits.
- Add non-combatants with team ID "10" and "Narcos/Civ\<1-8\>" kit.

## Kill Confirmed (Semi-Permissive)

This variant is generated via the script "ReplaceLowVizKitsInMis.sed".

## Break Out

Start with a copy of "Kill Confirmed".

- Remove all insertion points. Add a new insertion point called "Prison".
- Remove all HVT spawns.
- Add additional patrols and guards.

## Security Detail (Semi-Permissive, LowViz)

1. It can make sense to start from a "Kill Confirmed (Semi-Permissive, LowViz)" mission.

   For the following we will assume that we are editing "Small Town" with the following
   well-known (from "Intel Retrieval") InsertionPoint and ExtractionPoints:

    - InsertionPoint: North-East, South-East, South-West
    - ExtractionPoint: NE,SE,SW (near respective Spawn point); NWGate (Extraction behind Building A)

   Let us assume that we want to add the following VIP InsertionPoints:
 
   - VIP-North-East, VIP-South-East, VIP-South-West
   - VIP-In-Building-B, VIP-In-Building-D
   - VIP-In-Building-A (this one is just used in this text and not in the actual mission)

2. Understanding escape routes

   Some game modes pick a random ExtractionPoint indiscriminately.
   This would not work well for "Security Detail":
   For example for VIP-In-Building-A the ExtractionPoint NWGate (Extraction behind Building A) would be
   too easy to reach (it is too close, and you can use building A as partial cover).

   Therefore, we use a different strategy: You, as a mission maker, define which escape routes
   are allowed. This is done by linking the VIP InsertionPoints to ExtractionPoints via tags.

3. Tagging ExtractionPoints

   Each ExtractionPoint MUST have at least one tag in the form of "Exfil-TXT" (where TXT is some text). Multiple tags are allowed.

   For example, we could tag:
   - NE with "Exfil-NE" and "Exfil-East"
   - SE with "Exfil-SE" and "Exfil-East"
   - SW with "Exfil-SW" and "Exfil-West"
   - NWGate with "Exfil-NW" and "Exfil-West"

4. Tagging PSD (personal security detail) InsertionPoints

   Each non-VIP InsertionPoint MUST have at EXACTLY one tag in the form of "IP-TXT" (where TXT is some text).
   For example, we could tag InsertionPoint South-West with "IP-SW".

5. Adding VIP InsertionPoints for "Travel" scenario

   In the escort scenario we escort the VIP from one edge of the map to another.
   In this example we will create VIP-South-West:

   1. Create an InsertionPoint
            The name of the InsertionPoint is functionally irrelevant, however we suggest that you
            use something like "VIP:South-West".
   2. Add tag "VIP-Travel" and set the team ID to 1.
   3. Add PlayerStarts to the InsertionPoint via Editor button.
      Note that there must be _exactly_ one PlayerStart per VIP InsertionPoint. (Delete 7 of the 8 PlayerStarts.)
   4. Link the VIP to his extractions: Add one or more Exfil tags to the VIP InsertionPoint.
   5. Link the VIP to his PSD: Add the tag "IP-SW" to the VIP InsertionPoint.
   Note: When the "Available Forces" OPS board setting is set to "PSD only", only InsertionPoints linked to the VIP InsertionPoint (via tag) will be enabled.

6. Adding VIP InsertionPoints for "Exfil" scenario

   In the exfil scenario we escort the VIP from the inside of the map to an edge of the map.

    1. Create an InsertionPoint (same as 4.1)
    2. Add tag "VIP-Exfil" and set the team ID to 1.
    3. Add PlayerStarts via Editor button. (same as 4.3)
    4. Link the VIP to his extractions (same as 4.4)
    5. Create PSD InsertionPoint:
       Add an InsertionPoint with team ID 1. Use a name like "Building-B".
       Add the tag "Hidden", and a tag like "IP-B" to the InsertionPoint.
    6. Link the VIP to his PSD:
       Add the tag "IP-B" to the VIP InsertionPoint.
       When the "Available Forces" OPS board setting is set to "PSD only", only InsertionPoints linked to the VIP InsertionPoint (via tag) will be enabled.
    7. Create PSD PlayerStarts
       Create 7 (or 8) PlayerStarts
       Move the VIP PlayerStart so that the VIP is covered by his PSD.

7. Creating "Restricted" InsertionPoints

   By default, the script will put late comers (players that have not selected an InsertionPoint) to the VIP's PSD.

   For some PSD InsertionPoints you might not have enough space to place 7 PlayerStarts.
   In such cases tag the InsertionPoint with "Restricted" so that script will not use that InsertionPoint for late comers.

8. Testing

   1. If you run "Validate" in the mission editor the script will print all escape routes into the GB Log file.
   2. Individual Insertion Points can be activated on the OPS board via console command "DebugGameCommand reloadmissionscript loc=2".

## Asset Extraction (Semi-Permissive, LowViz)

The "Asset Extraction (Semi-Permissive, LowViz)" mission is the same as "Secuirty Detail (Semi-Permissive, LowViz)", with the following tweaks added:

- Add an InsertionPoint with tag "Asset"
- Add PlayerStarts to InsertionPoint via Editor button. Note that there must be _exactly_ one PlayerStart. (Delete 7 of the 8 PlayerStarts).
- Add orphaned (Group=None) PlayerStarts with tag "Asset"

## Security Detail (Semi-Permissive)

This variant is generated via the script "ReplaceLowVizKitsInMis.sed".

## Asset Extraction (Semi-Permissive)

This variant is generated via the script "ReplaceLowVizKitsInMis.sed".

## Security Detail/Asset Extraction

- Copy "Security Detail/Asset Extraction (Semi-Permissive, LowViz)"
- Replace all non-combatants AI (AI with team ID 10) kits with different "Nacro/*" kits and change the team ID to 100.

# Kit notes

In GROUND BRANCH v1034.2, AI can't use handguns. As a workaround handguns where replaced with 
"BP_MP5A5".

---
title: Asset Extraction
---

In _Asset Extraction_ you need to extract an _Asset_ (undercover agent).

**Type:** Solo, Coop, PvE.\
**Players:** 1-8.

## Objectives

* Protect the Asset. 
* Avoid collateral damage. (Only in _Semi-Permissive_ variant) 
* Extract via exfil point.

Variations:

1. _Asset Extraction_: Everyone is a combatant.
2. _Asset Extraction (Semi-Permissive)_: Combatant and non-combatants are present. Combatants are wearing balaclavas and chest rigs.
3. _Asset Extraction (Semi-Permissive, LowViz)_: Combatant and non-combatants are present. Combatants are using low visibility gear.

## Game play

1. One player selects the "_Asset_ (0/1)" insertion point. All other players select a regular insertion point.
2. Team and _Asset_ go to exfil point
3. The _Asset_ needs to survive.

**Note:** If no player has selected the "_Asset_ (0/1)" insertion point, a random player
will be made the _Asset_. (Players that have not selected an insertion point take precedence.)

## Settings

* **Expected resistance** - impacts the amount of enemies that will spawn in mission. 
The final Opposing Force count takes player count and this setting into account. 

## Admin console commands
 
Open the console via <kbd>F7</kbd> or <kbd>*</kbd> (Num Pad). On US keyboards you can also use <kbd>~</kbd>.\
Type:


<dl>
<dt><code>admin reloadmissionscript loc=<em>number</em></code></dt>
<dd>Select Asset spawn location. Will not be visible on OPS board. Use <code>0</code> for random.</dd>

<dt><code>admin reloadmissionscript help</code></dt>
<dd>Display help text.</dd>

<dt><code>admin reloadmissionscript rand</code></dt>
<dt><code>admin reloadmissionscript rand obj</code></dt>
<dd>Randomize objectives.</dd>

<dt><code>admin reloadmissionscript rand exfil</code></dt>
<dd>Pick a new random exfil point.</dd>
</dl>

**Note:** In single player mode type "`debuggamecommand`" instead of "`admin`".

## Additional notes

* The _Asset_ might want to dress up in OPFOR clothing.
* A mission editing guide can be found in "AssetExtraction.lua".

---
title: Security Detail
---

In _Security Detail_ you need to protect the _principal_/_VIP_.

**Type:** Solo, Coop, PvE.\
**Players:** 1-8.

## Objectives

* Protect the Principal. 
* Avoid collateral damage. (Only in _Semi-Permissive_ variant) 
* Extract via exfil point.

## Game play

1. One player selects the "_VIP_ (0/1)" insertion point. All other players select a regular insertion point.
2. Team and _VIP_ go to exfil point
3. The _VIP_ needs to survive.

**Note:** By default, if no player has selected the "_VIP_ (0/1)" insertion point, a random player
will be made the _VIP_. (Players that have not selected an insertion point take precedence.)

## Settings

* **Available forces**
  * "PSD only": All players need to insert near the _VIP_. (PSD: Private security detail/detachment)
  * "QRF only": All players need to insert far away from the _VIP_. (QRF: Quick reaction force)
  * "PSD and QRF": Players can insert everywhere. 
* **Expected resistance** - impacts the amount of enemies that will spawn in mission. 
The final Opposing Force count takes player count and this setting into account. 
* **Scenario**
  * "Travel": Escort the _VIP_ from random edge of the map to another edge of the map. 
  * "Exfil": Escort the _VIP_ from a building to a random edge of the map.
  * "Random (Exfil/Travel)": Randomly selects one of the above every round.
* **VIP**
  * "Mandatory": This is the default setting.  If no player has selected the "_VIP_ (0/1)" insertion point, a player
    will be automatically selected as the _VIP_. Players that have not selected an insertion point have precedence over players
    that have selected an insertion point.
  * "Optional": Disables automatic selection of the VIP. The round can be successfully completed without him/her. Intended for _improvised_ game modes.
  
## Admin console commands

Open the console via <kbd>F7</kbd> or <kbd>*</kbd> (Num Pad). On US keyboards you can also use <kbd>~</kbd>.\
Type:

<dl>
<dt><code>admin reloadmissionscript loc=<em>number</em></code></dt>
<dd>Select VIP insertion point. Will be visible on OPS board. Use <code>0</code> for random.</dd>

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

* The _VIP_ might want to use a pistol.
* A mission editing guide can be found in "SecurityDetail.lua".

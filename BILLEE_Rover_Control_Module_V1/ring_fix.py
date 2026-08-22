import pcbnew
board = pcbnew.GetBoard()

TARGET_RING = pcbnew.FromMM(0.075)   # your proven JLC value
TOL = pcbnew.FromMM(0.001)           # tiny tolerance so already-compliant vias are left alone

changed = 0
for track in board.GetTracks():
    if track.Type() == pcbnew.PCB_VIA_T:
        drill = track.GetDrillValue()
        width = track.GetWidth()
        ring = (width - drill) / 2
        if ring < TARGET_RING - TOL:
            track.SetWidth(drill + 2 * TARGET_RING)
            changed += 1

print(f"Changed {changed} vias")
pcbnew.Refresh()
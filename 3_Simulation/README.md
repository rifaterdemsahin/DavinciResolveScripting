# 3_Simulation - UI & Layouts

## UI Requirements

While many scripts will be headless (no UI), complex workflows may require a GUI (using PySide2/FusScript) to:

1. **Select Assets**: File pickers for overlays, images, and graphics.
2. **Configuration**: Sliders/inputs for audio normalization target levels (e.g., -14 LUFS).
3. **Marker Input**: Text area to paste timestamp data for marker generation.

## Technologies

* **DaVinci Resolve UI API** (via `UIDispatcher`)
* **Python (PySide2/PyQt5)** for external configuration tools if needed.

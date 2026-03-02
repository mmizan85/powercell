# ============================================================
#  PowerCell — PyInstaller Build Spec
#  Builds a standalone Windows .exe with icon embedded
#
#  Usage:
#    pip install pyinstaller
#    pyinstaller installers/build_exe.spec
#
#  Output: dist/PowerCell.exe
# ============================================================

import os

block_cipher = None

a = Analysis(
    ['PowerCell.py'],
    pathex=[os.path.abspath('.')],
    binaries=[],
    datas=[
        ('assets/powercell.ico',     'assets'),
        ('assets/powercell_256.png', 'assets'),
    ],
    hiddenimports=[
        'platform',
        'subprocess',
        'shutil',
        'ctypes',
        'ctypes.windll',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['tkinter', 'matplotlib', 'numpy', 'PIL'],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='PowerCell',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,          # CLI app — keep console window
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='assets/powercell.ico',
    version_file=None,
    # Embed version info
    description='PowerCell - Cross-Platform Software Installer',
    company_name='Mohammad Mizanur Rahman',
    copyright='Copyright © 2024 Mohammad Mizanur Rahman',
    product_version='2.0.0.0',
    file_version='2.0.0.0',
)

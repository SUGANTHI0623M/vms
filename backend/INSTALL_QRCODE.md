# Installing QR Code Dependencies

The QR code feature requires the `qrcode` and `Pillow` packages to be installed.

## Installation

Run the following command in your terminal:

```bash
pip install qrcode Pillow
```

Or if you're using a virtual environment:

```bash
python -m pip install qrcode Pillow
```

## Alternative Installation Methods

If you encounter network issues, try:

1. **Using a different index:**
   ```bash
   pip install --index-url https://pypi.org/simple qrcode Pillow
   ```

2. **Installing from requirements.txt:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Using conda (if available):**
   ```bash
   conda install -c conda-forge qrcode pillow
   ```

## Verification

After installation, verify it works:

```python
python -c "import qrcode; import PIL; print('QR code packages installed successfully')"
```

## Note

The server will start without these packages, but QR code generation will be disabled until they are installed.

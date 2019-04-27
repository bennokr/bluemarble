## Make small statically-hosted blue marble tiles ##
# Requirements: gdal, python3, imagemagick

# Download
wget "https://eoimages.gsfc.nasa.gov/images/imagerecords/57000/57752/land_shallow_topo_21600.tif"

# Scale
convert land_shallow_topo_21600.tif -resize 16384x16384 land_shallow_topo_16384.tif

# Georeference
gdal_translate -a_srs EPSG:4326 -a_ullr -180 +90 +180 -90 land_shallow_topo_16384.tif bluemarble-16384.tiff

# Crop out poles
gdal_translate  -projwin -180 70 180 -70 bluemarble-16384.tiff bluemarble-16384-crop.tif

# Warp to Web Mercator
gdalwarp -t_srs EPSG:3857 -r lanczos -wo SOURCE_EXTRA=1000 -co COMPRESS=LZW bluemarble-16384-crop.tif bluemarble-16384-crop-wm.tif # huge (~1gb)

# Crop
gdal_translate -of JPEG -co QUALITY=70 -co PROGRESSIVE=ON bluemarble-16384-crop-wm.tif bluemarble-16384-crop-wm.jpg # tiny (~10mb)
# Resize & Pad to power of 2
convert bluemarble-16384-crop-wm.jpg -resize 16384x16384 -background black -gravity center -extent 16384x16384 bluemarble-16384-crop-wm-square.jpg # slow (~10min)

# Make tiles
python3 gdal2tiles.py -v -l -p raster -z 0-6 -w none bluemarble-16384-crop-wm-square.jpg tiles > tiles.log

# Convert tiles to gif
find tiles -name "*.png" | while read f; do mkdir -p $(dirname $f | sed 's/tiles/tiles_gif/'); convert $f -strip -coalesce -layers Optimize -colors 32 $(echo $f | sed 's/tiles/tiles_gif/;s/png/gif/'); done

# Remove empty tiles
find tiles_gif -name "*.gif" -exec sh -c 'echo {} $(md5 -q {})' \; | grep $(md5 -q tiles_gif/6/0/0.gif) | cut -d' ' -f1 | xargs rm    
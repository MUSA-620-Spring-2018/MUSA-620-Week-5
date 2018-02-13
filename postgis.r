
library(RPostgreSQL)
library(sf)
library(postGIStools)
library(tidyverse)
library(viridis)
library(classInt)

myTheme <- function() {
  theme_void() + 
    theme(
      text = element_text(size = 7),
      plot.title = element_text(size = 14, color = "#eeeeee", hjust = 0, vjust = 0, face = "bold"), 
      plot.subtitle = element_text(size = 12, color = "#cccccc", hjust = 0, vjust = 0),
      axis.ticks = element_blank(),
      panel.grid.major = element_line(colour = "#333333"),
      panel.background = element_rect(fill = "#333333"),
      plot.background = element_rect(fill = "#333333"),
      legend.direction = "vertical", 
      legend.position = "right",
      plot.margin = margin(0, 0, 0, 0, 'cm'),
      legend.key.height = unit(1, "cm"), legend.key.width = unit(0.4, "cm"),
      legend.title = element_text(size = 12, color = "#eeeeee", hjust = 0, vjust = 0, face = "bold"),
      legend.text = element_text(size = 8, color = "#cccccc", hjust = 0, vjust = 0)
    ) 
}

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "spatialdb",
                 host = "127.0.0.1", port = 5432,
                 user = "postgres", password = '')



# create a simple spatial table manually
dbGetQuery(con, "CREATE TABLE geometries (name varchar, geom geometry)")

sqlQuery <- paste0("INSERT INTO geometries VALUES",
"('Point', 'POINT(3 3)'),",
"('Linestring', 'LINESTRING(-1 -1, -2 -2, -3 -2, -3 -3)'),",
"('Polygon', 'POLYGON((-4 4, -3 4, -3 3, -4 3, -4 4))'),",
"('PolygonWithHole', 'POLYGON((5 5, 10 5, 10 10, 5 10, 5 5),(6 6, 6 7, 7 7, 7 6, 6 6))'),",
"('Collection', 'GEOMETRYCOLLECTION(POINT(-2 3),POLYGON((0 0, 1 0, 1 1, 0 1, 0 0)))');")

dbGetQuery(con, sqlQuery)

# Let's have a look at what's inside this table
dbGetQuery(con, "SELECT name, ST_AsText(geom) FROM geometries")

# Query the data directly into SF format
geoExample = st_read_db(con, query = "SELECT * FROM geometries", geom_column = 'geom')
plot(geoExample)

# geometry_columns stores metadata about all geospatial tables
dbGetQuery(con, "SELECT * FROM geometry_columns")

# SRID = coordinate reference system
# Set the SRID for our table
dbGetQuery(con, "SELECT UpdateGeometrySRID('geometries','geom',4326)")



# add Philly shapefile to the database
phillySF <- st_read('d:/philly-census-tract.shp', stringsAsFactors = FALSE)
plot(phillySF)

# we want lowercase fields 
phillySF <- rename(phillySF, gisjoin = GISJOIN)

# import SF object into a new table
st_write_db(con, phillySF, "phillysf")

# let's see what the geometry column is called -- "wkb_geometry"
dbGetQuery(con, "SELECT * FROM geometry_columns")

# export table into an SF object
philly = st_read_db(con, query = "SELECT * FROM phillysf", geom_column = 'wkb_geometry')
plot(philly)



# Next, we are going to find the nearest Septa station to each tract

# transform to Mercator CRS -- we are about to do a distance calculation, so we need a distance-preserving CRS
phillySF <- st_transform(phillySF, 3785)

# import to the database, overwriting the previous one
st_write_db(con, phillySF, "phillysf", drop = TRUE)
dbGetQuery(con, "SELECT UpdateGeometrySRID('phillysf','wkb_geometry',3785)")

# Septa stations
septa <- st_read('d:/SEPTAGISRegionalRailStations_2016.shp', stringsAsFactors = FALSE)
plot(septa)

# columns to lowercase
septa <- rename(septa, line_name = Line_Name, station_name = Station_Na)

# transform to Mercator
septa <- st_transform(septa, 3785)

# import into the database
st_write_db(con, septa, "septa")

#phillySpatialJoin <- st_read_db(con, query=joinQuery, geom_column='geom')


# select just the Septa stations that are in Philadelphia proper
spatialQuery <- paste0("SELECT s.* ",
                    "FROM phillysf AS p, septa AS s ",
                    "WHERE ST_Contains(p.wkb_geometry, s.wkb_geometry)")

stationsInPhilly <- st_read_db(con, query=spatialQuery, geom_column='wkb_geometry')

ggplot() +
  geom_sf(data = phillySF, fill="#bbbbbb", color = NA) +
  geom_sf(data = septa, colour = "red", size = 2) +
  geom_sf(data = stationsInPhilly, colour = "cyan", size = 1) +
  myTheme()


#st_write_db(con, stationsInPhilly, "septa")


# For each Census tract, find the distance from the nearest station
spatialQuery <- paste0("SELECT DISTINCT ON (p.gisjoin) p.gisjoin, p.wkb_geometry as geom, s.line_name as line, s.station_name as station, ",
                    "ST_Distance(p.wkb_geometry, s.wkb_geometry) AS distance ",
                    "FROM phillysf AS p, septa AS s ",
                    "ORDER BY p.gisjoin, ST_Distance(p.wkb_geometry, s.wkb_geometry) ASC")

phillySpatialJoin <- st_read_db(con, query=spatialQuery, geom_column='geom')

# by distance to station
ggplot() +
  geom_sf(data = phillySpatialJoin, aes(fill = distance), color = NA) +
  geom_sf(data = stationsInPhilly, colour = "blue", size = 1) +
  scale_fill_viridis(discrete = FALSE, direction = -1, option="magma") +
  myTheme()

# by Septa line
ggplot() +
  geom_sf(data = phillySpatialJoin, aes(fill = line), color = NA) +
  geom_sf(data = stationsInPhilly, colour = "white", size = 2) +
  scale_fill_brewer(palette="Paired") +
  myTheme()



# add U.S. traffic crash data, 2004-2013

accidents <- read.csv("d:/downloads/accidents_2004-2013.csv")
accidentsSF <- st_as_sf(accidents, coords = c("longitud", "latitude"), crs = 4326)
accidentsSF <- st_transform(accidentsSF, 3785)

# add to the database
st_write_db(con, accidentsSF, "accidents")




# count the number of accidents per tract - time how long the query takes to run
startTime <- Sys.time()
spatialQuery <- paste0("SELECT p.wkb_geometry as geom, p.gisjoin, COUNT(a.wkb_geometry) AS acc ",
        "FROM phillysf AS p, accidents AS a ",
        "WHERE ST_Contains(p.wkb_geometry, a.wkb_geometry) ",
        "GROUP BY (p.wkb_geometry, p.gisjoin)")
accidentCount <- st_read_db(con, query=spatialQuery, geom_column='geom')
endTime <- Sys.time()
endTime - startTime


# plot the accident count
natural <- classIntervals(accidentCount$acc, n=6, style="jenks")
accidentCount$accidents <- factor(
  cut(as.numeric(accidentCount$acc), c(0,natural$brks))
)
ggplot() +
  geom_sf(data = accidentCount, aes(fill = accidents), color = "#606060") +
  scale_fill_viridis(discrete = TRUE, direction = 1, option="inferno") +
  myTheme()



# add spatial index
dbGetQuery(con, "CREATE INDEX phillysf_gix ON phillysf USING GIST (wkb_geometry)")
dbGetQuery(con, "CREATE INDEX accidents_gix ON accidents USING GIST (wkb_geometry)")

# try the same query as above, see if it runs faster now
startTime <- Sys.time()
spatialQuery <- paste0("SELECT p.wkb_geometry as geom, p.gisjoin, COUNT(a.wkb_geometry) AS acc ",
                       "FROM phillysf AS p, accidents AS a ",
                       "WHERE ST_Contains(p.wkb_geometry, a.wkb_geometry) ",
                       "GROUP BY (p.wkb_geometry, p.gisjoin)")
accidentCount <- st_read_db(con, query=spatialQuery, geom_column='geom')
endTime <- Sys.time()
endTime - startTime



# see if we can attach the accidents to a specific street segment

# add Philly's road network
phillyStreets <- st_read('Street_Centerline.shp', stringsAsFactors = FALSE)
phillyStreets <- st_transform(phillyStreets, 3785)
phillyStreets <- rename(phillyStreets,seg_id=SEG_ID)
st_write_db(con, phillyStreets, "phillystreets")
dbGetQuery(con, "CREATE INDEX phillystreets_gix ON phillystreets USING GIST (wkb_geometry)")

# isolate the accidents in Philly
spatialQuery <- paste0("SELECT a.* ",
                       "FROM phillysf AS p, accidents AS a ",
                       "WHERE ST_Contains(p.wkb_geometry, a.wkb_geometry)")
accidentsInPhilly <- st_read_db(con, query=spatialQuery, geom_column='wkb_geometry')
accidentsInPhilly <- rename(accidentsInPhilly ,oldgeom=wkb_geometry)
st_write_db(con, accidentsInPhilly, "accidentsinphilly",drop=TRUE)
dbGetQuery(con, "CREATE INDEX accidentsinphilly_gix ON accidentsinphilly USING GIST (wkb_geometry)")



# For each Census tract, find the distance from the nearest station

# *** BAD QUERY *** This would work, but it would take a very long time
spatialQuery <- paste0("SELECT DISTINCT ON (a.wkb_geometry) a.*, p.seg_id, ",
                       "ST_Distance(a.wkb_geometry, p.wkb_geometry) AS distance ",
                       "FROM accidentsinphilly AS a, phillystreets AS p ",
                       "ORDER BY a.wkb_geometry, ST_Distance(a.wkb_geometry, p.wkb_geometry) ASC")

# This is better
spatialQuery <- paste0("SELECT DISTINCT ON (a.wkb_geometry) a.*, p.seg_id, ",
     "ST_Distance(a.wkb_geometry, p.wkb_geometry) AS distance ",
     "FROM accidentsinphilly AS a, phillystreets AS p ",
     "WHERE ST_Distance(a.wkb_geometry, p.wkb_geometry) < 1000", # ***** THIS IS THE IMPORTANT ONE
     "ORDER BY a.wkb_geometry, ST_Distance(a.wkb_geometry, p.wkb_geometry) ASC")

# Let's time it
startTime <- Sys.time()
accidentsWithNearestRoad <- st_read_db(con, query=spatialQuery, geom_column='wkb_geometry')
endTime <- Sys.time()
endTime - startTime






# it's always good practice to disconnect from the database once you're done
dbDisconnect(con)
dbUnloadDriver(drv)



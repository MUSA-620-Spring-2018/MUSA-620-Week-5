# MUSA-620-Week-5
Databases: PostGIS and spatial queries

[FARS data](http://metrocosm.com/get-the-data/#accidents)

## Spatial Databases

![Distance from nearest SEPTA station Philadelphia](https://blueshift.io/distance-from-septa.png "Distance from nearest SEPTA station Philadelphia")
Distance from each building in Philadelpha to the nearest SEPTA station

## Assignment

Create a map that examines crime in Philadelphia at the street segment level.

This assignment is **required**. Please turn it in by email to myself (galkamaxd at gmail) and Evan (ecernea at sas dot upenn dot edu).

**Due:** 20-Feb before the start of class

### Description

Using PostGIS spatial queries and the datasets below, create a map that examines a crime trend of your choice in Philadelphia at the level of street segments.

- [10 years of Philadelphia crime](https://www.kaggle.com/mchirico/philadelphiacrimedata/version/19)
- [Philadelphia street segments](https://github.com/MUSA-620-Spring-2018/MUSA-620-Week-5/blob/master/STR_Centerline.zip)
- The two datasets above are the only ones that are required. However if it improves the analysis or presentation, you may also wish to include [Philadelphia Census tracts](https://github.com/MUSA-620-Spring-2018/MUSA-620-Week-1/blob/master/census-tracts-philly.zip) or another polygon GIS data source.

The crime dataset is quite large, so you should filter it down to a more specific sample depending on your topic of focus. Any topic is fair game, as long as the analysis involves at least 10,000 crime data points. Examples topics:

- The simplest case would be a count of crimes that have taken place on each segment. In this case, you may wish to restrict the data to a specific time period (e.g. just 2017) or a specific category or categories of crime (e.g. Public Drunkenness, Motor Vehicle Theft, etc)
- An examination of crimes in a particular area of the city (e.g. how do the crime levels change as you move away from the Penn campus?)
- A comparison of the geospatial distribution of types of crimes (e.g. violent vs non-violent crime)

The methods for creating the map should follow roughly this path:

- Make any necessary preparations to your tabular crime data: clean up columns, modify/add columns, remove NA/0 values, etc.
- Use a spatial query to associate each crime with the nearest street segment.
- Use another PostGIS query to join the aggregate crime data to each street segment.
- Use ggplot to visualize the results in a clear, compelling way.

This assignment is not intended as a purely technical exercise. **You should give careful consideration to design choices and defend your choices in the project description**. The goal is for the map to tell as clear a "story" as possible.
- Are the results best conveyed with color, line thickness, both?
- Are you using an appropriate color scheme? Number of colors? Well chosen break points?
- Does it include explanatory features (title, legend, etc) that make it clear for the viewer what they are looking at?

In your writeup, please include a few lines about the thought process behind your design choices.

### Tips for speeding up your queries <a id="queryspeed"></a>

In order of importance, here are three things you can do to make spatial queries run faster:

* **Create a spatial index on *all* of your spatial tables.** See the second to last example we went thru in class: `CREATE INDEX accidents_gix ON accidents USING GIST (wkb_geometry)`
* **Add a distance restriction in your WHERE clause.** See the last example we went thru in class: `WHERE ST_Distance(a.wkb_geometry, p.wkb_geometry) < 1000`. The 1000 used here was arbitrary. I came up with that number by looking at the data in QGIS, changing the project CRS to "Mercator," and eyeballing how far off the accident coordinates are from the streets in Mercator coordinates. Have a look yourself. You can probably get away with a much smaller number.
* **Cluster your spatial tables.** Essentially, this will rebuild the table so that geometries that are near each other in space will be closer together on the disk. The effect will be minor, but it should make your queries marginally faster. A clustering query is very simple and takes this form: `CLUSTER accidents USING accidents_gix`

### Deliverable

The final deliverable should include all of these items:
- the final map, as an image or PDF file
- all code used in the construction of the map
- a written explanation of: the steps you took to create it, reasons for your design choices, and an explanation of what the map shows / what patterns you see.

### Grading

Your project will be graded will on:
- Completion of the assignment as described
- Visual presentation (Does the map tell a clear story? Were the design choices well thought out and explained?)
- Concept + analysis (Was the project well thought out? What trends does it show? Did you identify anything that stands out?)

Code will be checked for correctness, but will otherwise not be factored into the grade.

### Extra credit:

As before, assigments that build upon the project description may receive extra credit, subject to prior approval. If you have an idea, please email me by the end of day Friday with your suggestion. Please be specific and include a link to any additional  dataset[s] you intend to use.

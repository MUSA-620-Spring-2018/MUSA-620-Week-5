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
- Use ggmap to visualize the results in a clear, compelling way.

This assignment is not intended as a purely technical exercise. **You should give careful consideration to design choices and explain your choices in the project description**. The goal is for the map to tell as clear a "story" as possible.
- Are the results best conveyed with color, line thickness, both?
- Are you using an appropriate color scheme? Number of colors? Well chosen break points?
- Does it include explanatory features (title, legend, etc) that make clear what you're looking at?

In your writeup, please include a few lines about the thought process behind your design choices.

### Data sources

- [Philadelphia Census tracts shapefile/geojson](https://www.opendataphilly.org/dataset/census-tracts)
- [Census ACS data portal](https://data2.nhgis.org/main)

If you have a preferred source of Census data, you are welcome collect the data from there.

### Deliverable

The final deliverable should include all of these items:
- the map itself
- all code used in the construction of the map
- a written explanation of: the steps you took to create it, reasons for your design choices, and anything else you would like to add about what the map shows / what patterns you see.

### Grading

Your project will be graded will be graded on:
- Completion of the map as described
- Visual presentation (Does the map tell a clear story? Were the design choices well thought out and explained?)
- Concept + analysis (Was the project well thought out? What trends stand out?)

Code will be checked for correctness, but will otherwise not be factored into the grade.

### Extra credit:

As before, assigments that build upon the project description may receive extra credit, subject to prior approval. If you have an idea, please email me by the end of day Friday with your suggestion. Please be specific and include a link to any additional  dataset[s] you intend to use.

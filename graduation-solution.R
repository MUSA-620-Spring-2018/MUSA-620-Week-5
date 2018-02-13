

require(tidyverse)
require(RPostgreSQL)


drv <- dbDriver("PostgreSQL")

# connect to the database
con <- dbConnect(drv, dbname = "musa620",
                 host = "127.0.0.1", port = 5432,
                 user = "postgres", password = '')


# **** WHICH STUDENTS ARE ELLIGIBLE TO GRADUATE? ****
# Who has earned a grade of 80 or better in at least 4 courses?

# SOLUTION 1
sqlCommand <- paste0("SELECT s.name, COUNT(s.*) AS classes ", #This COUNT(s.*)...
                     "FROM enrollment AS e ",
                     "JOIN students AS s ",
                     "ON e.student_id = s.student_id ",
                     "WHERE e.numeric_grade >= 80 ",
                     "GROUP BY s.name ",
                     "HAVING COUNT(s.*) >= 4 ",   #...and this COUNT(s.*) are different
                     "ORDER BY classes DESC")
dbGetQuery(con, sqlCommand)

# SOLUTION 2
sqlCommand1 <- paste0("SELECT s.name,COUNT(e.*) AS num_classes ",
                     "FROM enrollment AS e ",
                     "JOIN students AS s ",
                     "ON e.student_id = s.student_id ",
                     "WHERE e.numeric_grade >= 80 ",
                     "GROUP BY s.name ")
sqlCommand2 <- paste0("SELECT * FROM (",
                      sqlCommand1,
                      ") AS subquery ",
                      "WHERE num_classes >= 4")
dbGetQuery(con, sqlCommand2)




dbDisconnect(con)
dbUnloadDriver(drv)



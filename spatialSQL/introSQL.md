# intro
### queries 
```sql
/*finding possible join fields and determining how to join*/
select count(distinct gisjoin),count(gisjoin) from table1940

select count(distinct, gisjoin),count(gisjoin) from tracts1940

/*joining table1940 to tracts1940*/
select*
from tracts1940 AS a left outer join table1940 as b
on a.gisjoin = b.gisjoin

/*joining table1940 to tracts1940 while selecting only new fields from table1940 to prevent duplicates
joins are given aliases (a and b)*/
select a.*, b.poptotal, b.white, b.nonwhite, b.medgrossrent
from tracts1940 as a left outer join table1940 as b
on a.gisjoin = b.gisjoin

/*ordering results*/
select a.*, b.poptotal, b.white, b.nonwhite, b.medgrossrent
from tracts1940 AS a left outer join table1940 as b
on a.gisjoin = b.gisjoin
order by medgrossrent desc

/*removing zero-rent values*/
select a.*, b.poptotal, b.white, b.nonwhite, b.medgrossrent
from tracts1940 as a left outer join table1940 AS b
on a.gisjoin = b.gisjoin
where medgrossrent>0
order by medgrossrent desc

/*creating a view of the query which can be viewed in qgis*/
create view join1940 as
select a.*, b.poptotal, b.white, b.nonwhite, b.medgrossrent
from tracts1940 as a LEFT OUTER join table1940 as b
on a.gisjoin = b.gisjoin
where medgrossrent>0
order by medgrossrent desc

/*calculating direction*/
select *,
degrees(ST_AZIMUTH((select st_centroid(st_transform(geom, 3395)) from cbd), st_centroid(st_transform(geom,3395)))) as cbddir
from tracts1940

/*calculating geodesic distance with geography data type*/
select *,
st_distance((select st_centroid(geography(st_transform(geom, 4326))) from cbd), st_centroid(geography(st_transform(geom,4326)))) as cbddist
from tracts1940

/*switching arround the poings for whatever reason while calculating distance*/
select *,
st_distance(st_centroid(geography(st_transform(geom,4326))),(select st_centroid(geography(ST_TRANSFORM(geom, 4326))) from cbd)) as cbddist
from tracts1940

/*combining distance and direction calculations in one query and creating a layer*/
select *,
degrees(ST_AZIMUTH((select st_centroid(st_transform(geom, 3395)) from cbd), st_centroid(st_transform(geom,3395)))) as cbddir,
st_distance((select st_centroid(geography(st_transform(geom, 4326))) from cbd), st_centroid(geography(st_transform(geom,4326)))) as cbddist
from tracts1940

/*selecting an new version of cbd with proper projection*/
select id, st_transform(geom,3528) as geom
from cbd

/*makng selection a permenant layer*/
create table cbd3528 as
select id, st_transform(geom,3528) as geom
from cbd

/*creating 5 km buffer around cbd*/
create  view cbd5km as
select id, st_buffer(geom,5000) as geom
from cbd3528

/*seeing which tracts intersect with the 5km buffer*/
select*
from join1940
where st_intersects(geom,(st_buffer((select geom from cbd3528),5000)))

/*practicing aggregate functions*/
select count(id) as countID, min(medgrossrent) as minRent, avg(medgrossrent) as avgRent, max(medgrossrent) as maxRent
from cbd1940

/*union*/
create view agg_cbd1940 as
select 1 as id, count(id) as countID, min(medgrossrent) as minRent, avg(medgrossrent) as avgRent, max(medgrossrent) as maxRent, st_union(geom) as geom
from cbd1940
```

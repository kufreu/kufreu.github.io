/* adding USA Contigious Lambert Conformal Projection to the database*/
INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 102004, 'ESRI', 102004, '+proj=lcc +lat_1=33 +lat_2=45 +lat_0=39 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs ', 'PROJCS["USA_Contiguous_Lambert_Conformal_Conic",GEOGCS["GCS_North_American_1983",DATUM["North_American_Datum_1983",SPHEROID["GRS_1980",6378137,298.257222101]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Lambert_Conformal_Conic_2SP"],PARAMETER["False_Easting",0],PARAMETER["False_Northing",0],PARAMETER["Central_Meridian",-96],PARAMETER["Standard_Parallel_1",33],PARAMETER["Standard_Parallel_2",45],PARAMETER["Latitude_Of_Origin",39],UNIT["Meter",1],AUTHORITY["EPSG","102004"]]');

/* seeing if projection was added */
 select*
 from spatial_ref_sys 
 where srid =102004;

/* adding geometry to dorian and november tables */ 
 alter table dorian add column geom geometry;
 alter table november add column geom geometry;

/* making points from lat/long columns and transforming */
 update dorian 
 set geom= st_transform(st_setsrid( st_makepoint(lng,lat),4326) ,102004);
 
 update november
 set geom= st_transform(st_setsrid( st_makepoint(lng,lat),4326) ,102004);
 
 
 /* removing unneeded states from analysis */
delete from counties  
 where statefp not in ('54', '51', '50', '47', '45', '44', '42', '39', '37',
 '36', '34', '33', '29', '28', '25', '24', '23', '22', '21', '18', '17',
 '13', '12', '11', '10', '09', '05', '01');
 

/* transforming counties */
 update counties 
 set geometry = st_transform(geom,102004);
 
 select populate_geometry_columns();
 
 /* adding county codes to tweets */
 update november 
 set geoid = counties.geoid 
 from counties
 where st_intersects(november.geom, counties.geom);
 
 update dorian 
 set geoid= counties.geoid 
 from counties
 where st_intersects(dorian.geom, counties.geom);
 

 
 /* creating tables to count the number of tweets per county */
 create table  dcount as 
 select geoid,
 count(geoid)
 from dorian
 group by geoid;
 
 create table ncount as 
 select geoid,
 count(geoid)
 from november
 group by geoid;
 
 
 /* adding tweet counts to dorian and november, though this really wasn't necessary*/
 alter table dorian add column tweetcount integer;
 alter table novebmer add column tweetcount integer;
 
 update dorian 
 set tweetcount= dcount.count
 from dcount
 where dcount.geoid=dorian.geoid;
 
 update november
 set tweetcount= ncount.count
 from ncount
 where ncount.geoid=november.geoid;
 
 
/* adding tweet counts to counties */
 alter table counties add column dcount integer;
 alter table counties add column ncount integer;
 
 update counties 
 set dcount= dcount.count
 from dcount
 where dcount.geoid=counties.geoid;
 
 
 update counties 
 set ncount= ncount.count
 from ncount
 where ncount.geoid=counties.geoid; 
 
 /* removing nulls from data */
 update counties 
 set ncount=0
 where ncount is null;
 
 update counties 
 set dcount=0
 where dcount is null;

/* normalizing tweets */ 
alter table counties add column tweetrate float8;
 
 update counties 
 set tweetrate=(dcount/10000)
 
 
 /*calculating normalized tweet difference index */
 alter table counties add column ndti float8;
 
 update counties 
 update counties
 set ndti= (dcount-ncount)/((dcount+ncount)*1.0)
 where  (dcount + ncount)>0;
 
 update counties 
 set ndti=0
 where ndti=null;
 

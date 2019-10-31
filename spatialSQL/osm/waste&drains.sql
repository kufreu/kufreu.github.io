/*fixing geometries and reprojecting*/
create table wards37s as
select id, fid, ward_name,
st_makevalid(st_transform(geom,32737)) as geom
from wards;

create table subwards37s as
select fid,
st_transform(geom,32737) as geom
from subwards;

create table waste37s as
select id,
st_transform(geom, 32737) as geom
from waste;

create table drains37s as
select id,
st_transform(geom,32737) as geom
from drains;

select populate_geometry_columns();

/*adding spatial indices*/
create index sidx_wards37s_geom
on wards37s
using GIST(geom);

create index sidx_subwards37s_geom
on subwards37s
using GIST(geom);

create index sidx_drains37s_geom
on drains37s
using GIST(geom);

create index sidx_waste37s_geom
on waste37s
using GIST(geom);

/*assigning drains and waste sites to wards and subwards*/
alter table drains37s add column ward text;

update drains37s
set ward=wards37s.ward_name
from wards37s
where st_intersects(drains37s.geom,wards37s.geom);

alter table drains37s add column subward float8;

update drains37s
set subward=subwards37s.fid
from subwards37s
where st_intersects(drains37s.geom,subwards37s.geom);

alter table waste37s add column ward text;

update waste37s
set ward=wards37s.ward_name
from wards37s
where st_intersects(waste37s.geom,wards37s.geom);


alter table waste37s add column subward float8;

update waste37s
set subward=subwards37s.fid
from subwards37s
where st_intersects(waste37s.geom,subwards37s.geom);

/* finding distance from drains to waste sites*/
create table distfromdrain as
select drains37s.id as drains, waste37s.id as waste,
st_distance(geography(st_transform(drains37s.geom, 4326)), geography(st_transform(waste37s.geom, 4326))) as dist
from drains37s, waste37s
where st_intersects(st_buffer(drains37s.geom,50), waste37s.geom);

/*finding minimum distance between drains and waste sites */
create table mindistfromdrain as
select drains, min(dist) as dist
from distfromdrain
group by drains;

/*averaging minimum distance for wards and subwards*/
create table wardminavg as
select b.ward, avg(dist)
from mindistfromdrain as a
left outer join drains37s as b
on a.drains=b.id
group by b.ward;

create table subwardminavg as
select b.subward, avg(dist)
from mindistfromdrain as a
left outer join drains37s as b
on a.drains=b.id
group by b.subward;

/*adding columns*/
alter table subwards37s
add column wastesites float8,
add column drains float8,
add column avgmindist float8;

/*counting number of drains and waste sites in each subward*/
update subwards37s
set wastesites=(
select count(waste37s.id)
from waste37s
where subwards37s.fid=waste37s.subward);

update subwards37s
set drains=(
select count(drains37s.id)
from drains37s
where subwards37s.fid=drains37s.subward);

/*adding average minimum distance to subwards*/
update subwards37s
set avgmindist=subwardminavg.avg
from subwardminavg
where subwards37s.fid=subwardminavg.subward;

/*adding columns*/
alter table wards37s
add column wastesites float8,
add column drains float8,
add column avgmindist float8;

/*counting number of drains and waste sites in each ward*/
update wards37s
set wastesites=(
select count(waste37s.id)
from waste37s
where wards37s.ward_name=waste37s.ward);

update wards37s
set drains=(
select count(drains37s.id)
from drains37s
where wards37s.ward_name=drains37s.ward);

/*adding average minimum distance to wards*/
update wards37s
set avgmindist=wardminavg.avg
from wardminavg
where wards37s.ward_name=wardminavg.ward;

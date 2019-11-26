/*What range of years does the provided database cover*/
SELECT 2007 - 1871 AS DateDiff;			   
	  
2/*Find the name and height of the shortest player in the database.
How many games did he play in? What is the name of the team for which he played?
result*/
select p.namegiven,p.playerid, min(p.height) as shortest_height,count(b.g) as Games from people as p
join batting as b
on p.playerid = b.playerid
where height is not null
group by p.namegiven,p.playerid
order by shortest_height asc 
limit 1;
/*Find all players in the database who played at Vanderbilt University. 
Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
Sort this list in descending order by the total salary earned.
Which Vanderbilt player earned the most money in the majors?
Result*/
select p.namefirst,p.namelast,sum(s.salary) over(partition by s.playerid order by s.salary)  as total_salary,s.lgid as league,sc.schoolname
from people as p
join salaries as s
on p.playerid = s.playerid
join collegeplaying as c
on p.playerid = c.playerid
join schools as sc
on c.schoolid = sc.schoolid
where sc.schoolname like 'Vander%'
group by p.namefirst,p.namelast,s.playerid,s.salary,s.lgid,sc.schoolname
order by total_salary desc
limit 1;

/*Using the fielding table, group players into three groups based on their position: 
label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield",
and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.*/

select yearid, count(po) as po,
case when pos = 'SS' or pos = '1B' then 'Outfield'
     when pos = '2B' or pos = '3B' then 'Infield'
	 when pos = 'P' or pos = 'C' then 'Battery'
	 else 'other' end as position
	 from fielding
	 where yearid = 2016
	 group by position,yearid
	 order by po desc;

/*Find the average number of strikeouts per game by decade since 1920. 
Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?*/

select g, round(avg(so),2) as avg_s0, round(avg(hr),2) as avghr,
case when yearid between 1920 and 1930 then '1920s'
      when yearid between 1930 and 1940 then '1930s'
	  when yearid between 1940 and 1950 then '1940s'
	  when yearid between 1950 and 1960 then '1950s'
	  when yearid between 1960 and 1970 then '1960s'
	  when yearid between 1970 and 1980 then '1970s'
	  when yearid between 1980 and 1990 then '1980s'
	  when yearid between 1990 and 2000 then '1990s'
	  when yearid between 2000 and 2010 then '2000s'
	  when yearid between 2010 and 2016 then '2010s'
	  end as decade

from batting
group by g,decade
order by decade asc;
/* other way of doing of same question*/
select floor(yearid/10)*10 as decade,
ROUND(AVG(so), 2) AS avg_strikeouts,
ROUND(AVG(hr), 2) AS avg_homers
FROM battingpost
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;



/*Find the player who had the most success stealing bases in 2016, 
where success is measured as the percentage of stolen base attempts which are successful. 
(A stolen base attempt results either in a stolen base or being caught stealing.) 
Consider only players who attempted at least 20 stolen bases.*/
select p.namegiven as name,sum(b.sb) as sb,sum(b.cs) as cs,cast(sum(b.sb) as float)/cast(sum(b.sb+b.cs) as float) *100 as success
from people as p
inner join batting as b
on p.playerid = b.playerid
where yearid = 2016 and b.sb > 20
group by p.namegiven,b.sb
order by success desc
limit 1;
/*From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
What is the smallest number of wins for a team that did win the world series? 
Doing this will probably result in an unusually small number of wins for a world series champion –
determine why this is the case. Then redo your query, excluding the problem year. 
How often from 1970 – 2016 was it the case that a team with the most wins also won the world series?
What percentage of the time?*/

with most_wins_by_year as (
    with win_ranks as (
        select
               yearid,
               teamid,
               w,
               wswin,
               row_number() over (partition by yearid order by w desc, wswin desc) as rank
        from teams
        where yearid between 1970 and 2016
    )
    select yearid, teamid
    from win_ranks
    where rank = 1
),
ws_wins_by_year as (
    select yearid, teamid
    from teams
    where wswin = 'Y'
        and yearid between 1970 and 2016
    group by yearid, teamid
)
select count(distinct mwby.yearid),
       2017 - 1970 - 1 as total_years,
       round(count(distinct mwby.yearid) / (2017 - 1970 - 1)::numeric, 2) * 100 as pct_did_win
from most_wins_by_year mwby
inner join ws_wins_by_year wwby
    on mwby.yearid = wwby.yearid
           AND mwby.teamid = wwby.teamid;
/*Using the attendance figures from the homegames table, 
find the teams and parks which had the top 5 average attendance per game in 2016 
(where average attendance is defined as total attendance divided by number of games). 
Only consider parks where there were at least 10 games played. 
Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.*/

select team as teamname,park as parkname, attendance/games as avg_attendance from homegames
where year = 2016 and games >= 10
order by avg_attendance desc
limit 5;
select team as teamname,park as parkname, attendance/games as avg_attendance from homegames
where year = 2016 and games >= 10
order by avg_attendance asc
limit 5;
/*Which managers have won the TSN Manager of the Year award in both the National League (NL)
and the American League (AL)? Give their full name and the teams that they were managing when they won the award.*/
select Nl_manager as manager from (select p.namefirst || ' ' || p.namelast as name, m.playerid, m.yearid ,m.teamid 
from people as p inner join awardsmanagers as am
on p.playerid = am.playerid
inner join managers as m on am.playerid = m. playerid and (am.yearid = m.yearid)
where am.lgid = 'NL' and am.awardid = 'TSN Manager of the Year'
group by p.namefirst || ' ' || p.namelast,m.playerid, m.yearid,m.teamid) as NL_manager,
(select p.namefirst || ' ' || p.namelast as name , m.playerid, m.yearid ,m.teamid
from people as p inner join awardsmanagers as am
on p.playerid = am.playerid
inner join managers as m on am.playerid = m. playerid and (am.yearid = m.yearid)
where am.lgid = 'AL' and am.awardid = 'TSN Manager of the Year'
group by p.namefirst || ' ' || p.namelast,m.playerid, m.yearid,m.teamid) as AL_manager
where NL_manager.name = Al_manager.name;

/*doing with other way*/
with nl_managers as (
select playerid, yearid
from awardsmanagers
where lgid = 'NL' and awardid = 'TSN Manager of the Year'
group by playerid, yearid
),
al_managers as(
select playerid, yearid
from awardsmanagers
where lgid = 'AL' and awardid = 'TSN Manager of the Year'
group by playerid, yearid
)
select al_m.playerid, p.namefirst || ' ' || p.namelast as full_name, m.yearid, m.teamid
from nl_managers as nl_m
inner join al_managers al_m using(playerid)
inner join people as p using (playerid)
left join managers as m on p.playerid = m.playerid and (m.yearid = al_m.yearid or m.yearid = nl_m.yearid)
group by al_m.playerid, full_name, m.yearid, teamid
order by al_m.playerid, yearid;

	   
	   
/*10 Analyze all the colleges in the state of Tennessee. Which college has had the most success in the major leagues. 
Use whatever metric for success you like - number of players, number of games, salaries, world series wins, etc*/

 select sc.schoolname as college,max(s.salary) as salary,s.lgid as league
 from schools as sc
 join collegeplaying as cp
 on sc.schoolid = cp.schoolid
 join salaries as s
 on s.playerid = cp.playerid
 where sc.schoolstate = 'TN'
 group by college,league
 order by salary desc;
 
 /*11 Is there any correlation between number of wins and team salary? 
 Use data from 2000 and later to answer this question. As you do this analysis,
 keep in mind that salaries across the whole league tend to increase together, 
 so you may want to look on a year-by-year basis.*/
 
 select s.yearid,corr(s.salary,t.w)
 from salaries as s
 inner join teams as t
 on s.yearid = t.yearid
 where  s.yearid > 2000
 group by s.yearid
 order by s.yearid asc;
 
 /*In this question, you will explore the connection between number of wins and attendance.

Does there appear to be any correlation between attendance at home games and number of wins?
Do teams that win the world series see a boost in attendance the following year?
What about teams that made the playoffs? 
Making the playoffs means either being a division winner or a wild card winner.*/

select h.games,corr(h.attendance,t.w)
from teams as t
inner join homegames as h
on h.team = t.teamid
group by h.games
order by h.games;

select * from homegames;
select * from teams;

select t.yearid,t.teamid,h.attendance, t.w,t.g
from homegames as h
inner join teams as t
on h.team = t.teamid
where wswin = 'Y'
group by t.yearid,t.teamid, h.attendance,t.w,t.g
order by h.attendance desc,t.w desc;

select t.yearid,t.teamid,h.attendance,t.w, t.divwin,t.wcwin,t.g
from homegames as h
inner join teams as t
on h.team = t.teamid
where t.divwin = 'Y' and t.teamid in (select teamid from teams  where wcwin = 'Y')
group by t.yearid,t.teamid, h.attendance,t.w,t.divwin,t.wcwin,t.g
order by t.w desc;

select teamid, divwin, wcwin from teams
where teamid in (select teamid from teams where wcwin ='Y')
and teamid in (select teamid from teams where divwin = 'Y')

/*It is thought that since left-handed pitchers are more rare, causing batters to face them less often,
that they are more effective. Investigate this claim and present evidence to either support or dispute this claim.
First, determine just how rare left-handed pitchers are compared with right-handed pitchers. 
Are left-handed pitchers more likely to win the Cy Young Award? 
Are they more likely to make it into the hall of fame?*/ 
/*First, determine just how rare left-handed pitchers are compared with right-handed pitchers*/

select total_count,left_count, right_count, right_count - left_count as diff
,round(left_count/total_count::numeric,2) * 100 as percents_left_players from
(select count(playerid) as total_count,(select count(playerid) from people where throws = 'L') as left_count,
 (select count(playerid) as right_id from people where throws = 'R') as right_count
from people) as subquery;

/*Are left-handed pitchers more likely to win the Cy Young Award*/

select left_people_award,right_people_award, Total_award, round(left_people_award/Total_award::numeric,2) * 100 as left_award_percent from
(select count(playerid) as total_count,(select count(p.playerid) from people as p
inner join awardsplayers as ap
on p.playerid = ap.playerid
where p.throws = 'L' and ap.awardid = 'Cy Young Award') as left_people_award,
(select count(p.playerid) from people as p
inner join awardsplayers as ap
on p.playerid = ap.playerid
where p.throws = 'R' and ap.awardid = 'Cy Young Award') as right_people_award,
(select count(p.playerid) from people as p
inner join awardsplayers as ap
on p.playerid = ap.playerid where ap.awardid = 'Cy Young Award') as Total_award
from people ) as subquery

/*Are they more likely to make it into the hall of fame?*/

select left_people_fame,right_people_fame,Players_fame, round(left_people_fame/Players_fame::numeric,2) * 100 as left_fame_percents from
(select count(playerid) as total_count,(select count(p.playerid) from people as p
inner join halloffame as hf
on p.playerid = hf.playerid
where p.throws = 'L' and ballots >= 75) as left_people_fame,
(select count(p.playerid) from people as p
inner join halloffame as hf
on p.playerid = hf.playerid
where p.throws = 'R' and ballots >= 75 ) as right_people_fame,
(select count(p.playerid) from people as p inner join halloffame as hf
 on p.playerid = hf.playerid where ballots > 75) as Players_fame
from people ) as subquery






 
 																			)
 
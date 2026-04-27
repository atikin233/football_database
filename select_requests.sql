-- 1. Все игроки с клубами и зарплатами по действующим контрактам
select
    p.full_name,
    pl.nick,
    c.club_name,
    ct.week_salary,
    ct.start_dt,
    ct.end_dt
from player pl
join person p
    on p.person_id = pl.person_id
join contract ct
    on ct.person_id = pl.person_id
join club c
    on c.club_id = ct.club_id
where ct.end_dt is null or ct.end_dt >= current_date
order by ct.week_salary desc, p.full_name asc;


-- 2. Количество игроков в каждом клубе по действующим контрактам
select
    c.club_name,
    count(distinct pl.person_id) as players_count
from club c
join contract ct
    on ct.club_id = c.club_id
join player pl
    on pl.person_id = ct.person_id
where ct.end_dt is null or ct.end_dt >= current_date
group by c.club_id, c.club_name
order by players_count desc, c.club_name asc;


-- 3. Игроки, забившие больше всего голов во всех матчах
select
    p.full_name,
    pl.nick,
    sum(ps.goal) as total_goals
from player_stats ps
join player pl
    on pl.person_id = ps.player_id
join person p
    on p.person_id = pl.person_id
group by p.person_id, p.full_name, pl.nick
having sum(ps.goal) > 0
order by total_goals desc, p.full_name asc;


-- 4. Игроки, у которых голов больше среднего числа голов на игрока
with player_goals as (
    select
        ps.player_id,
        sum(ps.goal) as total_goals
    from player_stats ps
    group by ps.player_id
)
select
    p.full_name,
    pl.nick,
    pg.total_goals
from player_goals pg
join player pl
    on pl.person_id = pg.player_id
join person p
    on p.person_id = pl.person_id
where pg.total_goals > (
    select avg(total_goals)
    from player_goals
)
order by pg.total_goals desc, p.full_name asc;


-- 5. Судьи и количество матчей, которые они обслужили
select
    p.full_name as referee_name,
    r.category,
    count(g.game_id) as games_count
from referee r
join person p
    on p.person_id = r.person_id
left join game g
    on g.main_ref_id = r.person_id
group by p.person_id, p.full_name, r.category
order by games_count desc, referee_name asc;


-- 6. Турниры и среднее число голов за матч в каждом турнире
select
    l.league_name,
    t.start_year,
    round(avg(g.home_goals + g.away_goals)::numeric, 2) as avg_goals_per_game
from tournament t
join league l
    on l.league_id = t.league_id
join game g
    on g.tournament_id = t.tournament_id
group by t.tournament_id, l.league_name, t.start_year
order by avg_goals_per_game desc, l.league_name asc, t.start_year asc;


-- 7. Клубы, участвовавшие более чем в одном турнире
select
    c.club_name,
    count(ctt.tournament_id) as tournaments_count
from club c
join club_to_tournament ctt
    on ctt.club_id = c.club_id
group by c.club_id, c.club_name
having count(ctt.tournament_id) > 1
order by tournaments_count desc, c.club_name asc;


-- 8. Матчи с погодой, где было забито не менее 3 голов
select
    g.game_id,
    hc.club_name as home_club_name,
    ac.club_name as away_club_name,
    g.home_goals,
    g.away_goals,
    w.weather_type,
    w.temperature,
    w.wind_speed
from game g
join club hc
    on hc.club_id = g.home_club
join club ac
    on ac.club_id = g.away_club
left join weather w
    on w.weather_id = g.weather_id
where g.home_goals + g.away_goals >= 3
order by (g.home_goals + g.away_goals) desc, g.game_id asc;


-- 9. Средние коэффициенты по типам ставок
select
    b.type_of_bet,
    round(avg(b.coef_yes)::numeric, 2) as avg_coef_yes,
    round(avg(b.coef_no)::numeric, 2) as avg_coef_no,
    count(*) as bets_count
from bet b
group by b.type_of_bet
order by b.type_of_bet asc;


-- 10. Люди с несколькими гражданствами
select
    p.person_id,
    p.full_name,
    count(n.country) as nations_count,
    string_agg(n.country, ', ' order by n.country) as citizenships
from person p
join nationality nat
    on nat.person_id = p.person_id
join nation n
    on n.nation_id = nat.nation_id
group by p.person_id, p.full_name
having count(n.country) > 1
order by nations_count desc, p.full_name asc;

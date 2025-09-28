-- Q1 Are there any tables with duplicate or missing null values? If so, how would you handle them
-- Finding Duplicates

-- Table Users
   
SELECT username, COUNT(*) AS count
FROM users
GROUP BY username
HAVING COUNT(*) > 1;
    
-- Table photos

SELECT user_id, image_url, COUNT(*) AS count
FROM photos
GROUP BY user_id, image_url
HAVING COUNT(*) > 1;

SELECT  image_url, COUNT(*) AS count
FROM photos
GROUP BY  image_url
HAVING COUNT(*) > 1;

-- Table Comments

SELECT user_id, photo_id, comment_text, COUNT(*) AS count
FROM comments
GROUP BY user_id, photo_id, comment_text
HAVING COUNT(*) > 1;

-- Table Likes

SELECT user_id, photo_id, COUNT(*) AS count
FROM likes
GROUP BY user_id, photo_id
HAVING COUNT(*) > 1;

-- Table Follows 

SELECT follower_id, followee_id, COUNT(*) AS count
FROM follows
GROUP BY follower_id, followee_id
HAVING COUNT(*) > 1;

-- Table Photo_tags

SELECT photo_id, tag_id, COUNT(*) AS count
FROM photo_tags
GROUP BY photo_id, tag_id
HAVING COUNT(*) > 1; 

-- ----------------------------------------------------NO_Duplicate_Found--------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------  
-- Finding Null
-- Users Table

SELECT * FROM users
WHERE username IS NULL OR created_at IS NULL;

-- Photos table

SELECT * FROM photos
WHERE image_url IS NULL OR user_id IS NULL OR created_dat IS NULL;

-- Comments table

SELECT * FROM comments
WHERE comment_text IS NULL OR user_id IS NULL OR photo_id IS NULL OR created_at IS NULL;

-- Likes table

SELECT * FROM likes
WHERE user_id IS NULL OR photo_id IS NULL OR created_at IS NULL;

-- Follows table

SELECT * FROM follows
WHERE follower_id IS NULL OR followee_id IS NULL OR created_at IS NULL;

--  Tags table

SELECT * FROM tags
WHERE tag_name IS NULL OR created_at IS NULL;

--  Photo_Tags table

SELECT * FROM photo_tags
WHERE photo_id IS NULL OR tag_id IS NULL;

-- ---------------------------------------------------------NO Null Found -------------------------------------------------------------------------------------------
--  -----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TRIM WHITESPACES
-- User table

UPDATE users
SET username = TRIM(username)
WHERE username != TRIM(username); 

-- photos Table

UPDATE photos 
SET image_url = TRIM(image_url)
WHERE image_url != TRIM(image_url);

-- Comments Table 

UPDATE comments
SET comment_text = TRIM(comment_text)
WHERE comment_text != TRIM(comment_text);

-- Tags Table

UPDATE tags
SET tag_name = TRIM(tag_name)
WHERE tag_name != TRIM(tag_name);

-- --------------------------------------------------NO WHITESPACES------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Updating Column name

ALTER TABLE photos 
CHANGE COLUMN created_dat 
created_at TIMESTAMP DEFAULT NOW();

-- ------------------------------------------------Column name updated-----------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Standardizing text format
--  User Table
UPDATE users 
SET username = LOWER(username);

-- Tags Table 

UPDATE tags
SET tag_name = LOWER(tag_name);

-- Comments Table 

UPDATE comments 
SET comment_text = LOWER(comment_text);

-- ------------------------------------------------Updated Text to Lower -------------------------------------------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Verifying Foreign Key Consistency
-- Comments Table

SELECT * FROM comments
WHERE user_id NOT IN (SELECT id FROM users)
   OR photo_id NOT IN (SELECT id FROM photos);
   
-- Photos Table

SELECT * FROM photos
WHERE user_id NOT IN (SELECT id FROM users);

-- Likes Table 

SELECT * FROM likes
WHERE user_id NOT IN (SELECT id FROM users)
   OR photo_id NOT IN (SELECT id FROM photos);
   
-- Follows Table

SELECT * FROM follows
WHERE follower_id NOT IN (SELECT id FROM users)
	OR followee_id NOT IN (SELECT id FROM users);
    
-- Photo_tags Table

SELECT * FROM photo_tags
WHERE photo_id NOT IN (SELECT id FROM photos)
	OR tag_id NOT IN (SELECT id FROM tags);
    
-- ----------------------------------------Foregin Keys are consistent----------------------------------------------------------------------------------------------
--  ---------------------------------------------------------------------------------------------------------------------------------------------------------------- 
--  ===================+++OBJECTIVE QUESTIONS+++====================== 
-- Q2. What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base

select
	U.id,
	U.username,
    count(distinct P.id) as Number_of_posts,
    count(distinct L.photo_id) as Number_of_likes,
    count(distinct C.id) as Number_of_Comments
from users U 
left join photos p ON U.id = P.user_id
left join likes L ON U.id = L.user_id
left join comments C ON U.id = C.user_id
group by U.id,U.username;

-- ----------------------------------------------------------------------
-- Q3. Calculate the average number of tags per post (photo_tags and photos tables).

SELECT AVG(tag_count) AS avg_tags_per_photo
FROM (
    SELECT P.id, COUNT(PT.tag_id) AS tag_count
    FROM photos P 
    LEFT JOIN photo_tags PT ON P.id = PT.photo_id
    GROUP BY P.id
) AS tag_counts;


-- ----------------------------------------------------------------
--  Q4	Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.

with Engagement_rank as (
select 
	id,
    username,
    coalesce(round(((Total_Comments+Total_Likes)/Total_Post),2),0) as Engagement_rate
from (
	select 
		U.id,
        U.username,
		count(photo_id) Total_Post,
		sum(number_of_Comments) as Total_Comments,
		sum(number_of_Likes) as Total_Likes
	from users U 
    left join (
			select 
				P.user_id,
				P.id as Photo_id,
				count(distinct C.id) as number_of_Comments,
				count(distinct L.user_id) as number_of_Likes
			from photos P 
			left join comments C on P.id = C.photo_id
			left join likes L on P.id = L.photo_id
			group by P.id, user_id
) X on U.id = X.user_id
	group by U.id
) RN
)
select 
	*,
    dense_rank() over (order by	Engagement_rate desc) as `Rank`
from Engagement_rank;

-- -----------------------------------------------------------------------------
-- Q5. Which users have the highest number of followers and followings

select 
	U.id,
    U.username,
    count(distinct F1.follower_id) as Total_follower,
    count(distinct F.followee_id) as Total_followee
from users U 
left join follows F on U.id = F.follower_id
left join  follows F1 on U.id = F1.followee_id
group by U.id,U.username
order by Total_followee desc,Total_follower desc;

-- -------------------------------------------------------------------------
-- Q6.	Calculate the average engagement rate (likes, comments) per post for each user
  
  with Engagements as (
			select 
				P.user_id,
				P.id as Photo_id,
				(count(distinct C.id) + count(distinct L.user_id)) as Total_Engagement
			from photos P 
			left join comments C on P.id = C.photo_id
			left join likes L on P.id = L.photo_id
			group by P.id, user_id
)
select 
	user_id,
    U.username,
    round(avg(Total_Engagement),2) as AVG_Enagement_per_post
from Engagements E
join users U on E.user_id = U.id
group by user_id
order by AVG_Enagement_per_post desc;

-- ----------------------------------------------------------------------------------------------------
-- Q7. Get the list of users who have never liked any post (users and likes tables)

select 
	id,
    username
from users
where id not in (
	select user_id from likes
);

-- -----------------------------------------------------------------------------------------------------
-- Q8  How can you leverage user-generated content (posts, hashtags, photo tags) to create more personalized and engaging ad campaigns

-- Most Popular tags 

select T.id,T.tag_name, count(photo_id)  as total_photos  
from photo_tags PT
join tags T on PT.tag_id = T.id
group by tag_id
having total_photos >= 20
order by total_photos desc;


-- Users who posted under Popular tags

with Popular_tags as (
select T.id,T.tag_name, count(photo_id)  as total_photos  
from photo_tags PT
join tags T on PT.tag_id = T.id
group by tag_id
having total_photos >= 20
)
select distinct U.id, U.username
from users U 
join photos P on U.id = P.user_id
join photo_tags PT on P.id = PT.photo_id
where PT.tag_id in (select id from popular_tags);



-- user who liked or commented on post with popular tags

with Popular_tags as (
		select T.id,T.tag_name, count(photo_id)  as total_photos  
		from photo_tags PT
		join tags T on PT.tag_id = T.id
		group by tag_id,T.tag_name
		having total_photos >= 20
	)
    
	select distinct C.user_id
	from comments C 
	join photos P on C.photo_id = P.id
	join photo_tags PT on P.id = PT.photo_id
	where PT.tag_id in (select id from popular_tags)
    
	union
    
	select distinct L.user_id
	from Likes L 
	join photos P on L.photo_id = P.id
	join photo_tags PT on P.id = PT.photo_id
	where PT.tag_id in (select id from popular_tags)	
	order by user_id;
    
-- -------------------------------------------------------------------------------------------------
-- Q9.	Are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)? 
--      How can this information guide content creation and curation strategies?
--  Tags with highest user engagements 
select 
	T.id,
    T.tag_name,
    count(distinct P.id) as Posts_count,
    count(distinct C.id) as Total_Comments,
    count(distinct L.user_id,L.photo_id) as Total_likes,
    round((count(distinct C.id) + count(distinct L.user_id,L.photo_id))/count(distinct P.id),2) as AVG_tag_engagement
FROM likes L
join photos P on L.photo_id = P.id
join comments C on P.id = C.photo_id
JOIN photo_tags PT ON P.id = PT.photo_id
JOIN tags T ON PT.tag_id = T.id
group by T.id,T.tag_name
order by AVG_tag_engagement desc;

-- ----------------------------------------------------------------------------------
-- Q10.	Calculate the total number of likes, comments, and photo tags for each user 

with Userwise_engagement as (
			select 
				P.user_id,
				P.id as Photo_id,
				count(distinct C.id) as number_of_Comments,
				count(distinct L.user_id) as number_of_Likes
			from photos P 
			left join comments C on P.id = C.photo_id
			left join likes L on P.id = L.photo_id
			group by P.id, user_id
),Userwise_posts_engagement as (
			select 
				user_id,
                count(photo_id) as Total_Post,
                sum(number_of_Comments) as Total_Comments_received,
				sum(number_of_Likes) as Total_Likes_received
			from Userwise_engagement
            group by user_id
),user_commented as (
			select
				user_id,
                count(id) as User_total_commented
			from comments
            group by user_id
),user_likes as ( 
			select
				user_id,
                count(photo_id) as User_total_liked
			from likes
            group by user_id
)
select 
		U.id,
        U.username,
		coalesce(Total_Post,0) as Total_Post,
		coalesce(Total_Comments_received,0) as Total_Comments_received,
        coalesce(Total_Likes_received,0) as Total_Likes_received,
        coalesce(User_total_commented,0) as User_total_commented,
        coalesce(User_total_liked,0)  as User_total_liked
from users U 
left join Userwise_posts_engagement UPE on U.id = UPE.user_id
left join user_commented UC on U.id = UC.user_id
left join user_likes UL on U.id = UL.user_id;
 
-- method 2:
with Userwise_engagement as (
			select 
				P.user_id,
				P.id as Photo_id,
				count(distinct C.id) as number_of_Comments,
				count(distinct L.user_id) as number_of_Likes
			from photos P 
			left join comments C on P.id = C.photo_id
			left join likes L on P.id = L.photo_id
			group by P.id, user_id
)
select 
		U.id,
        U.username,
		count(distinct UE.photo_id) as Total_Post,
        coalesce(sum(distinct number_of_Comments), 0) as Total_Comments_received,
		coalesce(sum(distinct number_of_Likes), 0) as Total_Likes_received,
        count(distinct C.id) as User_total_commented,
        count(distinct L.photo_id) as User_total_liked
	from users U 
    left join Userwise_engagement UE on U.id = UE.user_id
    left join comments C on U.id = C.user_id
    left join likes L on U.id = L.user_id
    group by U.id,U.username;
    
-- -----------------------------------------------------------------------------------------------------------------------------------
-- Q11 Rank users based on their total engagement (likes, comments, shares) over a month

select 
	engagement_month,
	id,
    username,
    Total_Engagement,
    dense_rank() over ( partition by engagement_month order by Total_Engagement desc) as RNK
from (
	select 
		U.id,
        U.username,
        (count(distinct C.id) + count(distinct L.photo_id)) as Total_Engagement,
        DATE_FORMAT(COALESCE(l.created_at, c.created_at), '%Y-%m') as engagement_month
	from users U 
    left join comments C on U.id = C.user_id 
    left join likes L on U.id = L.user_id
    group by U.id,U.username,engagement_month
    having Total_Engagement > 0
)as UserEngagement;

-- ---------------------------------------------------------------------------------------------------
-- Q12.	Retrieve the hashtags that have been used in posts with the highest average number of likes. Use a CTE to calculate the average likes for each hashtag first.

with Highest_avg_likes as (
select 
	T.id,
	T.tag_name, 
	round(avg(likes_count),2) avg_likes,
    rank() over (order by round(avg(likes_count),2) desc) as RNK
from tags T 
join photo_tags PT on T.id = PT.tag_id 
join photos P on P.id = PT.photo_id
join (select photo_id,count(user_id) as likes_count
		from likes group by photo_id
        ) as LikesCount on P.id = LikesCount.likes_count
group by T.id,T.tag_name
)
select 
	id,
	tag_name,
    avg_likes
from Highest_avg_likes
where RNK = 1;

-- --------------------------------------------------------------------------------------------------------
-- Q13.	Retrieve the users who have started following someone after being followed by that person 

select 
    F2.follower_id AS user_id,
    F2.followee_id AS followed_person_id,
    F1.created_at AS followed_first_at,
    F2.created_at AS followed_second_at
FROM
    follows AS F1 -- Represents the initial follow (Person B follows Person A)
INNER JOIN
    follows AS F2 ON F1.follower_id = F2.followee_id  -- B follows A, and A follows B
                   AND F1.followee_id = F2.follower_id
WHERE
    F2.created_at > F1.created_at -- User A followed Person B AFTER Person B followed User A
ORDER BY
    F2.created_at ASC;
    
    
select 
   *
FROM
    follows AS F1 -- Represents the initial follow (Person B follows Person A)
INNER JOIN
    follows AS F2 ON F1.follower_id = F2.followee_id  -- B follows A, and A follows B
                   AND F1.followee_id = F2.follower_id
WHERE
    F2.created_at > F1.created_at -- User A followed Person B AFTER Person B followed User A
ORDER BY
    F2.created_at ASC;
    
-- -------------------------------------------------------------------------------------------
-- Subjective Questions ---------------------
-- Q1.) 1.	Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users?

with User_age as (
select 
	U.id,
    timestampdiff(day,U.created_at,now()) as user_age_days
from users U
) ,
Engagement_score as (
select 
	distinct U.id,
    U.username,
    UA.user_age_days,
    count(distinct C.id)*2 as Comments_score,   -- assigning 2points for comment ,1 point for likes , 3 point for posts
    count(distinct  P.id)*3 as Posts_score,
    count(distinct L.photo_id) as Likes_score
from users U
left join comments C  on U.id = C.user_id
left join likes L  on U.id = L.user_id
left join User_age UA  on U.id = UA.id
left join Photos P  on U.id = P.user_id
group by U.id
),
Ranked_Users AS (
  SELECT 
    id,
    username,
    user_age_days,
    COALESCE(Comments_score, 0) + COALESCE(Posts_score, 0) + COALESCE(Likes_score, 0) AS Total_engage_score
  FROM Engagement_score
)
SELECT 
  id,
  username,
  user_age_days,
  Total_engage_score,
  DENSE_RANK() OVER (ORDER BY Total_engage_score DESC, user_age_days DESC) AS engagement_rank
FROM Ranked_Users
limit 10;

-- ---------------------------------------------------------------------------------------------------
-- Q2. For inactive users, what strategies would you recommend to re-engage them and encourage them to start posting or engaging again?

with inactive_user_score as (
select 
	U.id,
    U.username,
    count(distinct C.id)*2 as Comments_score,   -- assigning 2points for comment ,1 point for likes , 3 point for posts
    count(distinct  P.id)*3 as Posts_score,
    count(distinct L.photo_id) as Likes_score
from users U
left join comments C  on U.id = C.user_id
left join likes L  on U.id = L.user_id
left join Photos P  on U.id = P.user_id
group by U.id
),
Ranked_Inative_Users AS (
  SELECT 
    id,
    username,
    COALESCE(Comments_score, 0) + COALESCE(Posts_score, 0) + COALESCE(Likes_score, 0) AS Total_engage_score
  FROM inactive_user_score
)
SELECT 
  id,
  username,
  Total_engage_score,
  DENSE_RANK() OVER (ORDER BY Total_engage_score ASC) AS inactive_user_rank
FROM Ranked_Inative_Users
limit 20;

-- ---------------------------------------------------------------------------------------------------
-- Q3. Which hashtags or content topics have the highest engagement rates? How can this information guide content strategy and ad campaigns? 

WITH tag_engagement AS (
  SELECT 
    t.id AS tag_id,
    t.tag_name,
    COUNT(DISTINCT l.user_id) AS total_likes,
    COUNT(DISTINCT c.id) AS total_comments,
    COUNT(DISTINCT pt.photo_id) AS total_photos
  FROM tags t
  JOIN photo_tags pt ON t.id = pt.tag_id
  JOIN photos p ON pt.photo_id = p.id
  LEFT JOIN likes l ON p.id = l.photo_id
  LEFT JOIN comments c ON p.id = c.photo_id
  GROUP BY t.id, t.tag_name
),
engagement_rate AS (
  SELECT 
    tag_name,
    total_likes,
    total_comments,
    total_photos,
    (total_likes + total_comments) / total_photos AS engagement_per_photo
  FROM tag_engagement
  WHERE total_photos > 0
)
SELECT *
FROM engagement_rate
ORDER BY engagement_per_photo DESC
LIMIT 10;

-- -----------------------------------------------------------------------------------------------------------
--  Q4.

-- Hour based engagement:
WITH photo_stats AS (
  SELECT
    p.id AS photo_id,
    HOUR(p.created_at) AS post_hour
  FROM photos p
),
likes_count AS (
  SELECT 
    photo_id,
    COUNT(*) AS total_likes
  FROM likes
  GROUP BY photo_id
),
comments_count AS (
  SELECT 
    photo_id,
    COUNT(*) AS total_comments
  FROM comments
  GROUP BY photo_id
)
SELECT 
  ps.post_hour,
  COUNT(DISTINCT ps.photo_id) AS total_posts,
  COALESCE(SUM(lc.total_likes), 0) AS total_likes,
  COALESCE(SUM(cc.total_comments), 0) AS total_comments,
  ROUND(
    (COALESCE(SUM(lc.total_likes), 0) + COALESCE(SUM(cc.total_comments), 0)) / 
    COUNT(DISTINCT ps.photo_id), 
    2
  ) AS avg_engagement_per_post
FROM photo_stats ps
LEFT JOIN likes_count lc ON ps.photo_id = lc.photo_id
LEFT JOIN comments_count cc ON ps.photo_id = cc.photo_id
GROUP BY ps.post_hour
ORDER BY post_hour;

--  weekday based engagement 

WITH photo_stats AS (
  SELECT
    p.id AS photo_id,
    DAYNAME(p.created_at) AS post_day
  FROM photos p
),
likes_count AS (
  SELECT 
    photo_id,
    COUNT(*) AS total_likes
  FROM likes
  GROUP BY photo_id
),
comments_count AS (
  SELECT 
    photo_id,
    COUNT(*) AS total_comments
  FROM comments
  GROUP BY photo_id
)
SELECT 
  ps.post_day,
  COUNT(DISTINCT ps.photo_id) AS total_posts,
  COALESCE(SUM(lc.total_likes), 0) AS total_likes,
  COALESCE(SUM(cc.total_comments), 0) AS total_comments,
  ROUND(
    (COALESCE(SUM(lc.total_likes), 0) + COALESCE(SUM(cc.total_comments), 0)) / 
    COUNT(DISTINCT ps.photo_id), 
    2
  ) AS avg_engagement_per_post
FROM photo_stats ps
LEFT JOIN likes_count lc ON ps.photo_id = lc.photo_id
LEFT JOIN comments_count cc ON ps.photo_id = cc.photo_id
GROUP BY ps.post_day
ORDER BY ps.post_day;

-- --------------------------------------------------------------------------------------------------------------------------
-- Q5. Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns? 
--     How would you approach and collaborate with these influencers?

WITH followers_count AS (
  SELECT 
    followee_id AS user_id,
    COUNT(follower_id) AS total_followers
  FROM follows
  GROUP BY followee_id
),
posts_count AS (
  SELECT 
    user_id,
    COUNT(*) AS total_posts
  FROM photos
  GROUP BY user_id
),
likes_count AS (
  SELECT 
    p.user_id,
    COUNT(l.user_id) AS total_likes
  FROM photos p
  LEFT JOIN likes l ON p.id = l.photo_id
  GROUP BY p.user_id
),
comments_count AS (
  SELECT 
    p.user_id,
    COUNT(c.id) AS total_comments
  FROM photos p
  LEFT JOIN comments c ON p.id = c.photo_id
  GROUP BY p.user_id
)
SELECT 
  u.id,
  u.username,
  COALESCE(fc.total_followers, 0) AS followers,
  COALESCE(pc.total_posts, 0) AS posts,
  COALESCE(lc.total_likes, 0) AS likes,
  COALESCE(cc.total_comments, 0) AS comments,
  ROUND(
    (COALESCE(lc.total_likes, 0) + COALESCE(cc.total_comments, 0)) / 
    NULLIF(pc.total_posts, 0), 2
  ) AS engagement_rate
FROM users u
LEFT JOIN followers_count fc ON u.id = fc.user_id
LEFT JOIN posts_count pc ON u.id = pc.user_id
LEFT JOIN likes_count lc ON u.id = lc.user_id
LEFT JOIN comments_count cc ON u.id = cc.user_id
WHERE COALESCE(fc.total_followers, 0) > 50  -- influencer threshold
AND pc.total_posts >=5                      -- influencer threshold
ORDER BY engagement_rate DESC, followers DESC
limit 20;

-- -----------------------------------------------------------------------------------------------
-- Q6. Based on user behavior and engagement data, how would you segment the user base for targeted marketing campaigns or personalized recommendations?


WITH followers_count AS (
  SELECT 
    followee_id AS user_id,
    COUNT(*) AS followers
  FROM follows
  GROUP BY followee_id
),
posts_count AS (
  SELECT 
    user_id,
    COUNT(*) AS posts
  FROM photos
  GROUP BY user_id
),
likes_count AS (
  SELECT 
    user_id,
    COUNT(*) AS likes
  FROM likes
  GROUP BY user_id
),
comments_count AS (
  SELECT 
    user_id,
    COUNT(*) AS comments
  FROM comments
  GROUP BY user_id
),
engagement_data AS (
  SELECT 
    u.id,
    u.username,
    COALESCE(f.followers, 0) AS followers,
    COALESCE(p.posts, 0) AS posts,
    COALESCE(l.likes, 0) AS likes,
    COALESCE(c.comments, 0) AS comments
  FROM users u
  LEFT JOIN followers_count f ON u.id = f.user_id
  LEFT JOIN posts_count p ON u.id = p.user_id
  LEFT JOIN likes_count l ON u.id = l.user_id
  LEFT JOIN comments_count c ON u.id = c.user_id
)
--  Segment Category 
-- SELECT *,(likes + comments) / NULLIF(posts, 0) as engage,
--     CASE
--       WHEN followers >= 50 AND posts >= 5 AND (likes + comments) / NULLIF(posts, 0) > 20 THEN 'Influencer'
--       WHEN posts < 2 AND (likes + comments) >= 50 THEN 'Liker & Commenter'
--       WHEN posts <= 4 AND (likes + comments) >= 50 THEN 'Active Creator'
--       ELSE 'Passive User'
--     END AS user_segment
--   FROM engagement_data
--   order by user_segment

-- Segment Wise Count replace the above segment category  to excute this code
,
segmented_users AS (
  SELECT *,(likes + comments) / NULLIF(posts, 0) as engage,
    CASE
      WHEN followers >= 50 AND posts >= 5 AND (likes + comments) / NULLIF(posts, 0) > 20 THEN 'Influencer'
      WHEN posts < 2 AND (likes + comments) >= 50 THEN 'Liker & Commenter'
      WHEN posts <= 4 AND (likes + comments) >= 50 THEN 'Active Creator'
      ELSE 'Passive User'
    END AS user_segment
  FROM engagement_data
)
SELECT 
  user_segment,
  COUNT(*) AS user_count
FROM segmented_users
GROUP BY user_segment
ORDER BY user_count DESC;

-- -------------------------------------------------------------------------------------------------------
 
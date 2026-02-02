---
layout: default
title: 文章归档
description: 所有文章的时间线归档
---

<div class="page">
  <h1>文章归档</h1>
  
  <div class="archive">
    {% assign posts_by_year = site.posts | group_by_exp:"post","post.date | date: '%Y'" %}
    
    {% for year in posts_by_year %}
      <h2>{{ year.name }}</h2>
      
      {% assign posts_by_month = year.items | group_by_exp:"post","post.date | date: '%B'" %}
      
      {% for month in posts_by_month %}
        <h3>{{ month.name }}</h3>
        <ul class="post-list">
          {% for post in month.items %}
            <li>
              <span class="post-date">{{ post.date | date: "%Y-%m-%d" }}</span>
              <a class="post-title" href="{{ site.baseurl }}{{ post.url }}">{{ post.title }}</a>
              {% if post.tags.size > 0 %}
                <span class="post-tags">
                  {% for tag in post.tags %}
                    <a href="{{ site.url }}{{ site.baseurl }}/tags#{{ tag }}" class="tag">{{ tag }}</a>
                  {% endfor %}
                </span>
              {% endif %}
            </li>
          {% endfor %}
        </ul>
      {% endfor %}
    {% endfor %}
  </div>
</div>

<style>
  .archive {
    margin-top: 30px;
  }
  
  .archive h2 {
    margin-top: 40px;
    margin-bottom: 20px;
    color: #333;
    border-bottom: 2px solid #eee;
    padding-bottom: 10px;
  }
  
  .archive h3 {
    margin-top: 30px;
    margin-bottom: 15px;
    color: #666;
    font-size: 18px;
  }
  
  .post-list {
    list-style: none;
    padding: 0;
    margin: 0 0 30px 0;
  }
  
  .post-list li {
    margin-bottom: 12px;
    padding-bottom: 12px;
    border-bottom: 1px solid #f0f0f0;
  }
  
  .post-date {
    display: inline-block;
    width: 100px;
    color: #999;
    font-size: 14px;
  }
  
  .post-title {
    font-size: 16px;
    color: #333;
    text-decoration: none;
    transition: color 0.3s;
  }
  
  .post-title:hover {
    color: #0066cc;
  }
  
  .post-tags {
    display: inline-block;
    margin-left: 10px;
  }
  
  .post-tags .tag {
    display: inline-block;
    margin: 0 3px;
    padding: 2px 8px;
    background-color: #f0f0f0;
    border-radius: 3px;
    font-size: 12px;
    color: #666;
    text-decoration: none;
  }
  
  .post-tags .tag:hover {
    background-color: #e0e0e0;
  }
  
  @media (max-width: 768px) {
    .post-date {
      width: 80px;
      font-size: 12px;
    }
    
    .post-title {
      font-size: 14px;
    }
  }
</style>
#!/usr/bin/env ruby

entries = `find ./blog.jxck.io/entries -name *.md | sort -r`.split("\n").map{|file|
  `./mark.js #{file}`
  head = `head -n 1 #{file}`

  title = head.match(/\# \[.*\] (.*)/)[1]

  tags = head
    .scan(/\[(.+?)\]/)
    .map{|s| s.pop }
    .map{|tag| "<a>#{tag}</a>" }
    .reverse
    .join

  tagspan = "<span class=tags>#{tags}</span>"

  splitted = file.split("/")
  name = splitted.pop.gsub(".md", ".html")
  date = splitted.pop
  "<li><time datetime=#{date}>#{date}</time><a href=entries/#{date}/#{name}>#{title}</a>#{tagspan}"
}

puts <<-EOS
<!DOCTYPE html>
<meta charset=utf-8>
<meta name=viewport content="width=device-width,initial-scale=1">

<title>blog.jxck.io</title>
<link rel=stylesheet type=text/css href=//www.jxck.io/assets/css/style.css>

<header>
  <a class=logo href=//jxck.io><img src=https://jxck.io/assets/img/jxck.png></a>
  <a class=path href=/>blog.jxck.io</a>
</header>

<section class=archive>
  <h1><a href=#archive>Archive</a></h1>
  <h2><a href=#2016>2016</a></h2>
  <ul>
    #{entries.join("\n    ")}
  </ul>
</section>

<hr>

<footer>
  <address class=copyright>Copyright &copy; 2016 <a href=/>Jxck</a>. All Rights Reserved.</address>
</footer>
EOS

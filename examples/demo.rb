#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/ratamin"

columns = [
  Ratamin::Column.new(key: :id, label: "ID", width: 6),
  Ratamin::Column.new(key: :name, label: "Name", width: 20),
  Ratamin::Column.new(key: :email, label: "Email", width: 30),
  Ratamin::Column.new(key: :role, label: "Role", width: 10),
  Ratamin::Column.new(key: :bio, label: "Bio", type: :text)
]

rows = [
  {id: 1, name: "Alice", email: "alice@example.com", role: "admin", bio: "Software engineer with 10 years of experience in distributed systems and cloud infrastructure."},
  {id: 2, name: "Bob", email: "bob@example.com", role: "user", bio: "Designer"},
  {id: 3, name: "Charlie", email: "charlie@example.com", role: "user", bio: "Product manager focused on developer tools and platform engineering."},
  {id: 4, name: "Diana", email: "diana@example.com", role: "moderator", bio: "Community lead"},
  {id: 5, name: "Eve", email: "eve@example.com", role: "admin", bio: "Security researcher specializing in cryptographic protocols and zero-knowledge proofs."},
  {id: 6, name: "Frank", email: "frank@example.com", role: "user", bio: "Full-stack developer"},
  {id: 7, name: "Grace", email: "grace@example.com", role: "user", bio: "Data scientist working on ML pipelines and recommendation systems."},
  {id: 8, name: "Hank", email: "hank@example.com", role: "moderator", bio: "DevOps engineer"},
  {id: 9, name: "Ivy", email: "ivy@example.com", role: "user", bio: "Frontend developer passionate about accessibility and design systems."},
  {id: 10, name: "Jack", email: "jack@example.com", role: "user", bio: "Backend engineer focused on high-performance APIs and database optimization."},
]

data_source = Ratamin::ArrayDataSource.new(columns: columns, rows: rows)
app = Ratamin::App.new(data_source)
app.run

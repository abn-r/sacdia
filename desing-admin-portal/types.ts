import React from 'react';

export interface Member {
  id: string;
  name: string;
  email: string;
  role: 'Director' | 'Counselor' | 'Pathfinder' | 'Instructor' | 'Adventurer' | 'Secretary';
  club: string;
  date: string;
  status: 'Approved' | 'Pending' | 'Active' | 'Inactive';
  avatar?: string;
  age?: number;
  baptized?: boolean;
}

export interface StatCardProps {
  label: string;
  value: string | number;
  trend?: string;
  trendUp?: boolean;
  icon: React.ReactNode;
  subtitle?: string;
}

export interface NavItem {
  label: string;
  path: string;
  icon: React.ReactNode;
  badge?: number;
}
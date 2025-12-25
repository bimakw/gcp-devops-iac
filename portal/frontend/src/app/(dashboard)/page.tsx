'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { requests, environments, Request, Environment } from '@/lib/api';
import { useAuth } from '@/lib/auth';
import { FileText, CheckCircle, Clock, AlertCircle, Plus } from 'lucide-react';

export default function DashboardPage() {
  const { user, isApprover } = useAuth();
  const [recentRequests, setRecentRequests] = useState<Request[]>([]);
  const [envs, setEnvs] = useState<Environment[]>([]);
  const [stats, setStats] = useState({
    total: 0,
    pending: 0,
    approved: 0,
    applied: 0,
  });

  useEffect(() => {
    requests.list().then((data) => {
      setRecentRequests(data.slice(0, 5));
      setStats({
        total: data.length,
        pending: data.filter((r) => r.status === 'pending').length,
        approved: data.filter((r) => r.status === 'approved').length,
        applied: data.filter((r) => r.status === 'applied').length,
      });
    });
    environments.list().then(setEnvs);
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'approved':
      case 'applied':
        return 'bg-green-100 text-green-800';
      case 'pending':
        return 'bg-yellow-100 text-yellow-800';
      case 'rejected':
      case 'failed':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Dashboard</h1>
          <p className="text-muted-foreground">Welcome back, {user?.name}</p>
        </div>
        <Button asChild>
          <Link href="/requests/new">
            <Plus className="mr-2 h-4 w-4" />
            New Request
          </Link>
        </Button>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Requests</CardTitle>
            <FileText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.total}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending Approval</CardTitle>
            <Clock className="h-4 w-4 text-yellow-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.pending}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Approved</CardTitle>
            <CheckCircle className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.approved}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Applied</CardTitle>
            <AlertCircle className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.applied}</div>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Recent Requests */}
        <Card>
          <CardHeader>
            <CardTitle>Recent Requests</CardTitle>
            <CardDescription>Your latest infrastructure requests</CardDescription>
          </CardHeader>
          <CardContent>
            {recentRequests.length === 0 ? (
              <p className="text-sm text-muted-foreground">No requests yet</p>
            ) : (
              <div className="space-y-4">
                {recentRequests.map((req) => (
                  <Link
                    key={req.id}
                    href={`/requests/${req.id}`}
                    className="flex items-center justify-between rounded-lg border p-3 hover:bg-accent"
                  >
                    <div>
                      <p className="font-medium">{req.title}</p>
                      <p className="text-sm text-muted-foreground">
                        {req.resource_type?.display_name} - {req.environment?.display_name}
                      </p>
                    </div>
                    <Badge className={getStatusColor(req.status)}>{req.status}</Badge>
                  </Link>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Environments */}
        <Card>
          <CardHeader>
            <CardTitle>Environments</CardTitle>
            <CardDescription>Available deployment environments</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {envs.map((env) => (
                <div key={env.id} className="flex items-center justify-between rounded-lg border p-3">
                  <div>
                    <p className="font-medium">{env.display_name}</p>
                    <p className="text-sm text-muted-foreground">{env.description}</p>
                  </div>
                  {env.requires_approval && (
                    <Badge variant="outline">Requires Approval</Badge>
                  )}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Approver Quick Actions */}
      {isApprover && (
        <Card>
          <CardHeader>
            <CardTitle>Approver Actions</CardTitle>
            <CardDescription>Pending items requiring your attention</CardDescription>
          </CardHeader>
          <CardContent>
            <Button asChild variant="outline">
              <Link href="/approvals">View Pending Approvals</Link>
            </Button>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { requests, Request } from '@/lib/api';
import { useAuth } from '@/lib/auth';
import { toast } from 'sonner';
import { ArrowLeft, Send, Trash2 } from 'lucide-react';

export default function RequestDetailPage() {
  const params = useParams();
  const router = useRouter();
  const { user } = useAuth();
  const [request, setRequest] = useState<Request | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (params.id) {
      requests
        .get(params.id as string)
        .then(setRequest)
        .catch(() => toast.error('Failed to load request'))
        .finally(() => setLoading(false));
    }
  }, [params.id]);

  const handleSubmit = async () => {
    if (!request) return;
    try {
      const updated = await requests.submit(request.id);
      setRequest(updated);
      toast.success('Request submitted for approval');
    } catch (error) {
      toast.error(error instanceof Error ? error.message : 'Failed to submit');
    }
  };

  const handleDelete = async () => {
    if (!request || !confirm('Are you sure you want to delete this request?')) return;
    try {
      await requests.delete(request.id);
      toast.success('Request deleted');
      router.push('/requests');
    } catch (error) {
      toast.error(error instanceof Error ? error.message : 'Failed to delete');
    }
  };

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
      case 'draft':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-blue-100 text-blue-800';
    }
  };

  const formatDate = (date: string) => {
    return new Date(date).toLocaleString();
  };

  if (loading) {
    return (
      <div className="flex justify-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!request) {
    return (
      <div className="text-center py-12">
        <p className="text-muted-foreground">Request not found</p>
        <Button asChild className="mt-4">
          <Link href="/requests">Back to Requests</Link>
        </Button>
      </div>
    );
  }

  const isOwner = user?.id === request.requester_id;
  const canSubmit = isOwner && request.status === 'draft';
  const canDelete = isOwner && ['draft', 'rejected'].includes(request.status);

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="sm" asChild>
          <Link href="/requests">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Link>
        </Button>
      </div>

      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold">{request.title}</h1>
          <p className="text-muted-foreground">{request.description || 'No description'}</p>
        </div>
        <Badge className={getStatusColor(request.status)}>{request.status}</Badge>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Request Details</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">Environment</p>
                <p className="font-medium">{request.environment?.display_name}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Resource Type</p>
                <p className="font-medium">{request.resource_type?.display_name}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Requester</p>
                <p className="font-medium">{request.requester?.name}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Priority</p>
                <p className="font-medium capitalize">{request.priority}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Created</p>
                <p className="font-medium">{formatDate(request.created_at)}</p>
              </div>
              {request.submitted_at && (
                <div>
                  <p className="text-sm text-muted-foreground">Submitted</p>
                  <p className="font-medium">{formatDate(request.submitted_at)}</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Configuration</CardTitle>
            <CardDescription>Resource configuration parameters</CardDescription>
          </CardHeader>
          <CardContent>
            <pre className="bg-muted p-4 rounded-lg text-sm overflow-auto max-h-64">
              {JSON.stringify(request.configuration, null, 2)}
            </pre>
          </CardContent>
        </Card>
      </div>

      {request.terraform_plan && (
        <Card>
          <CardHeader>
            <CardTitle>Terraform Plan</CardTitle>
            <CardDescription>Preview of infrastructure changes</CardDescription>
          </CardHeader>
          <CardContent>
            <pre className="bg-muted p-4 rounded-lg text-sm overflow-auto max-h-96 font-mono">
              {request.terraform_plan}
            </pre>
          </CardContent>
        </Card>
      )}

      {request.estimated_cost > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Cost Estimate</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">${request.estimated_cost.toFixed(2)}/month</p>
          </CardContent>
        </Card>
      )}

      {/* Actions */}
      <div className="flex gap-4">
        {canSubmit && (
          <Button onClick={handleSubmit}>
            <Send className="h-4 w-4 mr-2" />
            Submit for Approval
          </Button>
        )}
        {canDelete && (
          <Button variant="destructive" onClick={handleDelete}>
            <Trash2 className="h-4 w-4 mr-2" />
            Delete
          </Button>
        )}
      </div>
    </div>
  );
}

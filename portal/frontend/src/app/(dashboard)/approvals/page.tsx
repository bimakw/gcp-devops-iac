'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { approvals, Approval } from '@/lib/api';
import { toast } from 'sonner';
import { CheckCircle, XCircle } from 'lucide-react';

export default function ApprovalsPage() {
  const [data, setData] = useState<Approval[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedApproval, setSelectedApproval] = useState<Approval | null>(null);
  const [action, setAction] = useState<'approve' | 'reject' | null>(null);
  const [comment, setComment] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const loadApprovals = () => {
    setLoading(true);
    approvals
      .list('pending')
      .then(setData)
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadApprovals();
  }, []);

  const handleAction = async () => {
    if (!selectedApproval || !action) return;
    setSubmitting(true);
    try {
      if (action === 'approve') {
        await approvals.approve(selectedApproval.id, comment);
        toast.success('Request approved');
      } else {
        await approvals.reject(selectedApproval.id, comment);
        toast.success('Request rejected');
      }
      setSelectedApproval(null);
      setAction(null);
      setComment('');
      loadApprovals();
    } catch (error) {
      toast.error(error instanceof Error ? error.message : 'Action failed');
    } finally {
      setSubmitting(false);
    }
  };

  const formatDate = (date: string) => {
    return new Date(date).toLocaleString();
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Pending Approvals</h1>
        <p className="text-muted-foreground">Review and approve infrastructure requests</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Pending Requests</CardTitle>
          <CardDescription>{data.length} requests awaiting approval</CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
          ) : data.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-muted-foreground">No pending approvals</p>
            </div>
          ) : (
            <div className="space-y-4">
              {data.map((approval) => (
                <div key={approval.id} className="border rounded-lg p-4">
                  <div className="flex items-start justify-between">
                    <div className="space-y-1">
                      <p className="font-medium">{approval.request?.title}</p>
                      <p className="text-sm text-muted-foreground">
                        {approval.request?.resource_type?.display_name} -{' '}
                        {approval.request?.environment?.display_name}
                      </p>
                      <p className="text-sm text-muted-foreground">
                        Requested by {approval.request?.requester?.name} on{' '}
                        {formatDate(approval.created_at)}
                      </p>
                    </div>
                    <div className="flex gap-2">
                      <Button
                        size="sm"
                        variant="outline"
                        className="text-green-600 hover:text-green-700"
                        onClick={() => {
                          setSelectedApproval(approval);
                          setAction('approve');
                        }}
                      >
                        <CheckCircle className="h-4 w-4 mr-1" />
                        Approve
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        className="text-red-600 hover:text-red-700"
                        onClick={() => {
                          setSelectedApproval(approval);
                          setAction('reject');
                        }}
                      >
                        <XCircle className="h-4 w-4 mr-1" />
                        Reject
                      </Button>
                    </div>
                  </div>
                  <div className="mt-4 p-3 bg-muted rounded-lg">
                    <p className="text-sm font-medium mb-2">Configuration</p>
                    <pre className="text-xs overflow-auto">
                      {JSON.stringify(approval.request?.configuration, null, 2)}
                    </pre>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Action Dialog */}
      <Dialog open={!!selectedApproval && !!action} onOpenChange={() => {
        setSelectedApproval(null);
        setAction(null);
        setComment('');
      }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {action === 'approve' ? 'Approve Request' : 'Reject Request'}
            </DialogTitle>
            <DialogDescription>
              {action === 'approve'
                ? 'Confirm approval for this infrastructure request'
                : 'Provide a reason for rejecting this request'}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <p className="font-medium">{selectedApproval?.request?.title}</p>
              <p className="text-sm text-muted-foreground">
                {selectedApproval?.request?.resource_type?.display_name} -{' '}
                {selectedApproval?.request?.environment?.display_name}
              </p>
            </div>
            <div>
              <label className="text-sm font-medium">
                Comment {action === 'reject' && <span className="text-red-500">*</span>}
              </label>
              <Input
                value={comment}
                onChange={(e) => setComment(e.target.value)}
                placeholder={action === 'approve' ? 'Optional comment' : 'Reason for rejection'}
              />
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => {
                setSelectedApproval(null);
                setAction(null);
                setComment('');
              }}
            >
              Cancel
            </Button>
            <Button
              onClick={handleAction}
              disabled={submitting || (action === 'reject' && !comment)}
              variant={action === 'approve' ? 'default' : 'destructive'}
            >
              {submitting ? 'Processing...' : action === 'approve' ? 'Approve' : 'Reject'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

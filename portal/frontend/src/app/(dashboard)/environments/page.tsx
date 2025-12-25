'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { environments, Environment } from '@/lib/api';
import { Server, Shield, MapPin } from 'lucide-react';

export default function EnvironmentsPage() {
  const [data, setData] = useState<Environment[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    environments
      .list()
      .then(setData)
      .finally(() => setLoading(false));
  }, []);

  const getEnvColor = (name: string) => {
    switch (name) {
      case 'prod':
        return 'border-red-200 bg-red-50';
      case 'staging':
        return 'border-yellow-200 bg-yellow-50';
      case 'dev':
        return 'border-green-200 bg-green-50';
      default:
        return 'border-gray-200 bg-gray-50';
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Environments</h1>
        <p className="text-muted-foreground">Available deployment environments</p>
      </div>

      {loading ? (
        <div className="flex justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
        </div>
      ) : (
        <div className="grid gap-6 md:grid-cols-3">
          {data.map((env) => (
            <Card key={env.id} className={getEnvColor(env.name)}>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle className="flex items-center gap-2">
                    <Server className="h-5 w-5" />
                    {env.display_name}
                  </CardTitle>
                  {env.requires_approval && (
                    <Badge variant="outline" className="bg-white">
                      <Shield className="h-3 w-3 mr-1" />
                      Protected
                    </Badge>
                  )}
                </div>
                <CardDescription>{env.description}</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-2 text-sm">
                  {env.gcp_project_id && (
                    <div className="flex items-center gap-2">
                      <span className="text-muted-foreground">Project:</span>
                      <code className="bg-white px-2 py-0.5 rounded text-xs">
                        {env.gcp_project_id}
                      </code>
                    </div>
                  )}
                  <div className="flex items-center gap-2">
                    <MapPin className="h-4 w-4 text-muted-foreground" />
                    <span>{env.region}</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}

'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { environments, resourceTypes, requests, Environment, ResourceType } from '@/lib/api';
import { toast } from 'sonner';
import { ArrowLeft, ArrowRight } from 'lucide-react';

type Step = 'environment' | 'resource' | 'config' | 'review';

export default function NewRequestPage() {
  const router = useRouter();
  const [step, setStep] = useState<Step>('environment');
  const [envs, setEnvs] = useState<Environment[]>([]);
  const [types, setTypes] = useState<ResourceType[]>([]);
  const [submitting, setSubmitting] = useState(false);

  const [formData, setFormData] = useState({
    title: '',
    description: '',
    environment_id: '',
    resource_type_id: '',
    configuration: {} as Record<string, unknown>,
    priority: 'normal',
  });

  const [selectedEnv, setSelectedEnv] = useState<Environment | null>(null);
  const [selectedType, setSelectedType] = useState<ResourceType | null>(null);

  useEffect(() => {
    environments.list().then(setEnvs);
    resourceTypes.list().then(setTypes);
  }, []);

  const handleEnvSelect = (id: string) => {
    const env = envs.find((e) => e.id === id);
    setSelectedEnv(env || null);
    setFormData({ ...formData, environment_id: id });
  };

  const handleTypeSelect = (id: string) => {
    const type = types.find((t) => t.id === id);
    setSelectedType(type || null);
    // Initialize config with defaults from schema
    const defaultConfig: Record<string, unknown> = {};
    if (type?.config_schema?.properties) {
      const props = type.config_schema.properties as Record<string, { default?: unknown }>;
      Object.entries(props).forEach(([key, val]) => {
        if (val.default !== undefined) {
          defaultConfig[key] = val.default;
        }
      });
    }
    setFormData({ ...formData, resource_type_id: id, configuration: defaultConfig });
  };

  const handleConfigChange = (key: string, value: unknown) => {
    setFormData({
      ...formData,
      configuration: { ...formData.configuration, [key]: value },
    });
  };

  const handleSubmit = async () => {
    setSubmitting(true);
    try {
      const result = await requests.create(formData);
      toast.success('Request created successfully');
      router.push(`/requests/${result.id}`);
    } catch (error) {
      toast.error(error instanceof Error ? error.message : 'Failed to create request');
    } finally {
      setSubmitting(false);
    }
  };

  const canProceed = () => {
    switch (step) {
      case 'environment':
        return !!formData.environment_id;
      case 'resource':
        return !!formData.resource_type_id;
      case 'config':
        return formData.title.trim() !== '';
      case 'review':
        return true;
      default:
        return false;
    }
  };

  const nextStep = () => {
    const steps: Step[] = ['environment', 'resource', 'config', 'review'];
    const currentIndex = steps.indexOf(step);
    if (currentIndex < steps.length - 1) {
      setStep(steps[currentIndex + 1]);
    }
  };

  const prevStep = () => {
    const steps: Step[] = ['environment', 'resource', 'config', 'review'];
    const currentIndex = steps.indexOf(step);
    if (currentIndex > 0) {
      setStep(steps[currentIndex - 1]);
    }
  };

  const renderConfigField = (key: string, schema: Record<string, unknown>): React.ReactNode => {
    const value = formData.configuration[key];
    const type = schema.type as string;
    const title = (schema.title as string) || key;
    const enumValues = schema.enum as string[] | undefined;

    if (enumValues) {
      return (
        <div className="space-y-2">
          <Label>{title}</Label>
          <Select
            value={String(value || '')}
            onValueChange={(v) => handleConfigChange(key, v)}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {enumValues.map((opt) => (
                <SelectItem key={opt} value={opt}>
                  {opt}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      );
    }

    if (type === 'boolean') {
      return (
        <div className="space-y-2">
          <Label>{title}</Label>
          <Select
            value={value ? 'true' : 'false'}
            onValueChange={(v) => handleConfigChange(key, v === 'true')}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="true">Yes</SelectItem>
              <SelectItem value="false">No</SelectItem>
            </SelectContent>
          </Select>
        </div>
      );
    }

    if (type === 'integer' || type === 'number') {
      return (
        <div className="space-y-2">
          <Label>{title}</Label>
          <Input
            type="number"
            value={String(value || '')}
            onChange={(e) => handleConfigChange(key, parseInt(e.target.value) || 0)}
            min={schema.minimum as number}
            max={schema.maximum as number}
          />
        </div>
      );
    }

    return (
      <div className="space-y-2">
        <Label>{title}</Label>
        <Input
          value={String(value || '')}
          onChange={(e) => handleConfigChange(key, e.target.value)}
        />
      </div>
    );
  };

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold">New Request</h1>
        <p className="text-muted-foreground">Create a new infrastructure provisioning request</p>
      </div>

      {/* Progress */}
      <div className="flex items-center gap-2">
        {['environment', 'resource', 'config', 'review'].map((s, i) => (
          <div key={s} className="flex items-center">
            <div
              className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                s === step
                  ? 'bg-primary text-primary-foreground'
                  : ['environment', 'resource', 'config', 'review'].indexOf(step) > i
                  ? 'bg-green-500 text-white'
                  : 'bg-muted text-muted-foreground'
              }`}
            >
              {i + 1}
            </div>
            {i < 3 && <div className="w-8 h-0.5 bg-muted" />}
          </div>
        ))}
      </div>

      {/* Step Content */}
      {step === 'environment' && (
        <Card>
          <CardHeader>
            <CardTitle>Select Environment</CardTitle>
            <CardDescription>Choose the target environment for your resources</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {envs.map((env) => (
              <div
                key={env.id}
                onClick={() => handleEnvSelect(env.id)}
                className={`p-4 rounded-lg border cursor-pointer transition-colors ${
                  formData.environment_id === env.id
                    ? 'border-primary bg-primary/5'
                    : 'hover:bg-accent'
                }`}
              >
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium">{env.display_name}</p>
                    <p className="text-sm text-muted-foreground">{env.description}</p>
                  </div>
                  {env.requires_approval && (
                    <span className="text-xs bg-yellow-100 text-yellow-800 px-2 py-1 rounded">
                      Requires Approval
                    </span>
                  )}
                </div>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {step === 'resource' && (
        <Card>
          <CardHeader>
            <CardTitle>Select Resource Type</CardTitle>
            <CardDescription>Choose the type of infrastructure to provision</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {types.map((type) => (
              <div
                key={type.id}
                onClick={() => handleTypeSelect(type.id)}
                className={`p-4 rounded-lg border cursor-pointer transition-colors ${
                  formData.resource_type_id === type.id
                    ? 'border-primary bg-primary/5'
                    : 'hover:bg-accent'
                }`}
              >
                <p className="font-medium">{type.display_name}</p>
                <p className="text-sm text-muted-foreground">{type.description}</p>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {step === 'config' && selectedType && (
        <Card>
          <CardHeader>
            <CardTitle>Configure {selectedType.display_name}</CardTitle>
            <CardDescription>Customize your resource configuration</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>Request Title *</Label>
              <Input
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                placeholder={`${selectedType.display_name} for ${selectedEnv?.display_name}`}
              />
            </div>
            <div className="space-y-2">
              <Label>Description</Label>
              <Input
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="Optional description"
              />
            </div>
            <div className="border-t pt-4 mt-4">
              <p className="font-medium mb-4">Resource Configuration</p>
              {selectedType.config_schema?.properties ? (
                Object.entries(
                  selectedType.config_schema.properties as Record<string, Record<string, unknown>>
                ).map(([key, schema]) => (
                  <div key={key}>{renderConfigField(key, schema)}</div>
                ))
              ) : null}
            </div>
          </CardContent>
        </Card>
      )}

      {step === 'review' && (
        <Card>
          <CardHeader>
            <CardTitle>Review Request</CardTitle>
            <CardDescription>Verify your request details before submitting</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">Title</p>
                <p className="font-medium">{formData.title}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Environment</p>
                <p className="font-medium">{selectedEnv?.display_name}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Resource Type</p>
                <p className="font-medium">{selectedType?.display_name}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Priority</p>
                <p className="font-medium capitalize">{formData.priority}</p>
              </div>
            </div>
            <div className="border-t pt-4">
              <p className="text-sm text-muted-foreground mb-2">Configuration</p>
              <pre className="bg-muted p-3 rounded-lg text-sm overflow-auto">
                {JSON.stringify(formData.configuration, null, 2)}
              </pre>
            </div>
            {selectedEnv?.requires_approval && (
              <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                <p className="text-sm text-yellow-800">
                  This environment requires approval. Your request will be reviewed by an approver
                  before resources are provisioned.
                </p>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Navigation */}
      <div className="flex justify-between">
        <Button variant="outline" onClick={prevStep} disabled={step === 'environment'}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Back
        </Button>
        {step === 'review' ? (
          <Button onClick={handleSubmit} disabled={submitting}>
            {submitting ? 'Creating...' : 'Create Request'}
          </Button>
        ) : (
          <Button onClick={nextStep} disabled={!canProceed()}>
            Next
            <ArrowRight className="ml-2 h-4 w-4" />
          </Button>
        )}
      </div>
    </div>
  );
}

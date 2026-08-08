import type { VercelRequest, VercelResponse } from '@vercel/node';
import crypto from 'crypto';

/**
 * PSE Office OS — Stripe webhook
 * Bundle: services.psemanagement.supergrok
 * URL: https://super-grok-office-pse-sent.vercel.app/api/stripe/webhook
 *
 * Env (Vercel only — never in git):
 *   STRIPE_WEBHOOK_SECRET
 *   STRIPE_SECRET_KEY (optional if using Stripe SDK)
 *
 * Dashboard events:
 *   checkout.session.completed
 *   customer.subscription.updated
 *   customer.subscription.deleted
 */

function forgeLicenseId(): string {
  const id = crypto.randomUUID().replace(/-/g, '').slice(0, 12);
  return `lic-pse-2054-${id}`;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const sig = req.headers['stripe-signature'];
  if (!sig || typeof sig !== 'string') {
    return res.status(400).json({ error: 'Missing stripe-signature' });
  }

  const secret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!secret) {
    console.error('STRIPE_WEBHOOK_SECRET not set');
    return res.status(500).json({ error: 'Webhook not configured' });
  }

  // Production: constructEvent with raw body
  // const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);
  // const event = stripe.webhooks.constructEvent(rawBody, sig, secret);
  const event = req.body as {
    type?: string;
    data?: {
      object?: {
        id?: string;
        customer?: string;
        customer_email?: string;
        customer_details?: { email?: string };
        subscription?: string;
        amount_total?: number;
        currency?: string;
        metadata?: Record<string, string>;
      };
    };
  };

  switch (event?.type) {
    case 'checkout.session.completed': {
      const session = event.data?.object;
      const license = forgeLicenseId();
      const email =
        session?.customer_email ||
        session?.customer_details?.email ||
        'unknown';

      const record = {
        license_id: license,
        bundle_id: 'services.psemanagement.supergrok',
        product: 'Super Grok Office',
        price_usd: 29,
        interval: 'month',
        customer: session?.customer,
        email,
        subscription: session?.subscription,
        session_id: session?.id,
        created_at: new Date().toISOString(),
        status: 'active',
      };

      // Persist license (KV / DB / email to admin). App unlocks Pro when
      // Key Forge sees an active license for this machine/account.
      console.log('PSE_LICENSE_PROVISIONED', JSON.stringify(record));

      return res.status(200).json({
        received: true,
        license_id: license,
        unlock: 'Operator Pro Plan',
      });
    }

    case 'customer.subscription.deleted': {
      console.log('PSE_LICENSE_REVOKED', event.data?.object?.id);
      return res.status(200).json({ received: true, status: 'revoked' });
    }

    case 'customer.subscription.updated': {
      console.log('PSE_LICENSE_UPDATED', event.data?.object?.id);
      return res.status(200).json({ received: true });
    }

    default:
      return res.status(200).json({ received: true });
  }
}

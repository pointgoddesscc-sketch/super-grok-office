import type { VercelRequest, VercelResponse } from '@vercel/node';

/**
 * Stripe webhook for Super Grok Office ($29/mo)
 * Endpoint: https://super-grok-office-pse-sent.vercel.app/api/stripe/webhook
 *
 * Events to enable in Dashboard:
 * - checkout.session.completed
 * - customer.subscription.updated
 * - customer.subscription.deleted
 *
 * After payment, license is marked active; the macOS app reads Pro status
 * and unlocks Operator Pro Plan (screenshot badge).
 */
export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const sig = req.headers['stripe-signature'];
  if (!sig) {
    return res.status(400).json({ error: 'Missing stripe-signature' });
  }

  // TODO: after re-auth, set STRIPE_WEBHOOK_SECRET in Vercel env (never in git)
  // const event = stripe.webhooks.constructEvent(rawBody, sig, process.env.STRIPE_WEBHOOK_SECRET!);

  const event = req.body as { type?: string; data?: { object?: Record<string, unknown> } };

  switch (event?.type) {
    case 'checkout.session.completed': {
      const session = event.data?.object;
      // Provision office license for customer → app unlocks Pro Plan
      console.log('checkout.session.completed', session?.['customer'], session?.['subscription']);
      break;
    }
    case 'customer.subscription.deleted': {
      console.log('subscription ended — revoke Pro');
      break;
    }
    default:
      break;
  }

  return res.status(200).json({ received: true });
}
